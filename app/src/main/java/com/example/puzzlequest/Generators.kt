package com.example.puzzlequest

import kotlin.math.ceil
import kotlin.random.Random

/**
 * مولّد الألغاز. كل مستوى له بذرة ثابتة، فيظهر اللغز نفسه في كل مرة
 * (ضروري لحفظ التقدم)، ويمكن توليد عدد غير محدود من المستويات بتغيير الحد.
 */
object PuzzleFactory {

    fun make(tier: Tier, level: Int): Puzzle {
        val r = Random(tier.ordinal * 100_000 + level * 37 + 11)
        // الأنواع تتناوب: تسلسل ← معادلة ← شكل مختلف
        return when ((level - 1 + tier.ordinal) % 3) {
            0 -> sequence(tier, level, r)
            1 -> equation(tier, level, r)
            else -> oddOne(tier, level, r)
        }
    }

    /** يختار من أول جزء من القائمة؛ يكبر الجزء مع رقم المستوى فتظهر الأنماط الأصعب تدريجياً. */
    private fun <T> pickRamp(list: List<T>, level: Int, r: Random): T {
        val n = ceil(list.size * level / LEVELS_PER_TIER.toDouble()).toInt().coerceIn(1, list.size)
        return list[r.nextInt(n)]
    }

    // ─────────────────────────── التسلسلات ───────────────────────────

    private fun sequence(tier: Tier, level: Int, r: Random): Puzzle {
        val families: List<(Random) -> SeqSpec> = when (tier) {
            Tier.EASY -> listOf<(Random) -> SeqSpec>(
                { x -> seqAdd(x) }, { x -> seqSub(x) }, { x -> seqDouble(x) }
            )
            Tier.MEDIUM -> listOf<(Random) -> SeqSpec>(
                { x -> seqSquares(x) }, { x -> seqTriple(x) }, { x -> seqGrowing(x) },
                { x -> seqAlternate(x) }, { x -> seqFib(x) }
            )
            Tier.HARD -> listOf<(Random) -> SeqSpec>(
                { x -> seqMulAdd(x) }, { x -> seqInterleave(x) }, { x -> seqPrimes(x) },
                { x -> seqCubes(x) }, { x -> seqSquarePlus(x) }
            )
        }
        val generator = pickRamp(families, level, r)
        val spec = generator(r)
        val last = spec.terms.last()
        val step = last - spec.terms[spec.terms.size - 2]
        // إجابات خاطئة مقنعة: الاستمرار بنفس الفرق الأخير، الضعف، وما حول الجواب
        val hints = listOf(
            spec.answer + 1, spec.answer - 1, last + step,
            last * 2, spec.answer + step, spec.answer + 2
        )
        val (options, index) = numberOptions(spec.answer, hints, r)
        return Puzzle(
            type = PuzzleType.SEQUENCE,
            prompt = Msg("q_sequence"),
            lines = spec.terms.map { it.toString() } + "?",
            query = null,
            options = options,
            answerIndex = index,
            explanation = spec.explanation
        )
    }

    /** 4 خيارات: الجواب + 3 خاطئة، كلها موجبة ومختلفة. */
    private fun numberOptions(answer: Int, hints: List<Int>, r: Random): Pair<List<String>, Int> {
        val wrong = hints.filter { it > 0 && it != answer }.distinct().shuffled(r).take(3).toMutableList()
        var delta = 1
        while (wrong.size < 3) {
            val up = answer + delta
            val down = answer - delta
            if (up !in wrong && wrong.size < 3) wrong.add(up)
            if (down > 0 && down !in wrong && wrong.size < 3) wrong.add(down)
            delta++
        }
        val all = (wrong + answer).shuffled(r)
        return all.map { it.toString() } to all.indexOf(answer)
    }

    // ─────────────────────────── المعادلات ───────────────────────────

    private val fruits = listOf("🍎", "🍌", "🍇", "🍓", "🍒", "🍊", "🍋", "🍉")

    private fun equation(tier: Tier, level: Int, r: Random): Puzzle {
        val e = fruits.shuffled(r)
        return when (tier) {
            Tier.EASY -> eqEasy(level, r, e)
            Tier.MEDIUM -> eqMedium(level, r, e)
            Tier.HARD -> eqHard(level, r, e)
        }
    }

    private fun rep(symbol: String, n: Int): String = List(n) { symbol }.joinToString(" + ")

    /** رمزان: المعادلة الأولى تكشف الأول، والثانية تكشف الثاني. */
    private fun eqEasy(level: Int, r: Random, e: List<String>): Puzzle {
        val hi = 5 + level / 6
        val x = r.nextInt(2, hi + 1)
        var y = r.nextInt(1, hi + 1)
        if (y == x) y = if (x < hi) x + 1 else x - 1
        val n = r.nextInt(2, 5)
        val a = e[0]
        val b = e[1]
        val lines = listOf("${rep(a, n)} = ${n * x}", "$a + $b = ${x + y}")
        val (options, index) = numberOptions(y, listOf(x, x + y, y + 1, y - 1, y + 2), r)
        return Puzzle(
            PuzzleType.EQUATION, Msg("q_equation"), lines, "$b = ?", options, index,
            Msg("eq.explain", listOf("$a = $x, $b = $y"))
        )
    }

    /** ثلاثة رموز بترتيب متسلسل: كل معادلة تكشف رمزاً جديداً بعد الذي قبله. */
    private fun eqMedium(level: Int, r: Random, e: List<String>): Puzzle {
        val hi = 7 + level / 10
        val x = r.nextInt(2, hi + 1)
        val y = r.nextInt(1, hi + 1)
        val z = r.nextInt(1, hi + 1)
        val a = r.nextInt(2, 4)
        val b = r.nextInt(1, 3)
        val c = r.nextInt(1, 3)
        val p = e[0]
        val q = e[1]
        val s = e[2]
        val lines = listOf(
            "${rep(p, a)} = ${a * x}",
            "$p + ${rep(q, b)} = ${x + b * y}",
            "$q + ${rep(s, c)} = ${y + c * z}"
        )
        val answer = x + y + z
        val hints = listOf(answer + 1, answer - 1, x + y, y + z, x + z, answer + 2)
        val (options, index) = numberOptions(answer, hints, r)
        return Puzzle(
            PuzzleType.EQUATION, Msg("q_equation"), lines, "$p + $q + $s = ?", options, index,
            Msg("eq.explain", listOf("$p = $x, $q = $y, $s = $z"))
        )
    }

    /** ثلاثة رموز في دائرة: (1+2) و(2+3) و(1+3)، والمطلوب حاصل ضرب اثنين. */
    private fun eqHard(level: Int, r: Random, e: List<String>): Puzzle {
        val hi = 9 + level / 6
        val values = (2..hi).shuffled(r).take(3)
        val x = values[0]
        val y = values[1]
        val z = values[2]
        val p = e[0]
        val q = e[1]
        val s = e[2]
        val lines = listOf("$p + $q = ${x + y}", "$q + $s = ${y + z}", "$p + $s = ${x + z}")
        val (query, answer, others) = when (r.nextInt(3)) {
            0 -> Triple("$p × $q = ?", x * y, listOf(x, y))
            1 -> Triple("$q × $s = ?", y * z, listOf(y, z))
            else -> Triple("$p × $s = ?", x * z, listOf(x, z))
        }
        val hints = listOf(
            answer + others[0], answer - others[0], answer + others[1], answer - others[1],
            x + y + z, answer + 1, answer - 1
        )
        val (options, index) = numberOptions(answer, hints, r)
        return Puzzle(
            PuzzleType.EQUATION, Msg("q_equation"), lines, query, options, index,
            Msg("eq.explain", listOf("$p = $x, $q = $y, $s = $z"))
        )
    }

    // ───────────────────────── الشكل المختلف ─────────────────────────

    private fun oddOne(tier: Tier, level: Int, r: Random): Puzzle {
        // عدد الأشكال المتشابهة: سهل 3، متوسط 4، صعب 5 (والمختلف واحد)
        val n = when (tier) {
            Tier.EASY -> 3
            Tier.MEDIUM -> 4
            Tier.HARD -> 5
        }
        val majorCandidates = CATEGORIES.filter { it.emojis.size >= n }
        val major = majorCandidates[r.nextInt(majorCandidates.size)]
        // سهل: فئة من عائلة بعيدة. متوسط وصعب: فئة من العائلة نفسها (أصعب في التمييز)
        val minorCandidates = if (tier == Tier.EASY) {
            CATEGORIES.filter { it.family != major.family }
        } else {
            CATEGORIES.filter { it.family == major.family && it.id != major.id }
        }
        val minor = minorCandidates[r.nextInt(minorCandidates.size)]
        val same = major.emojis.shuffled(r).take(n)
        val odd = minor.emojis[r.nextInt(minor.emojis.size)]
        val tiles = (same + odd).shuffled(r)
        return Puzzle(
            type = PuzzleType.ODD_ONE,
            prompt = Msg("q_odd"),
            lines = emptyList(),
            query = null,
            options = tiles,
            answerIndex = tiles.indexOf(odd),
            explanation = Msg("odd.explain", listOf("@cat.${major.id}", "@cat.${minor.id}"))
        )
    }
}

// ─────────────────────── مواصفات التسلسلات ───────────────────────

/** [terms] الأعداد الظاهرة، و[answer] العدد التالي، و[explanation] قاعدة النمط. */
internal class SeqSpec(val terms: List<Int>, val answer: Int, val explanation: Msg)

private fun pow(base: Int, exp: Int): Int {
    var p = 1
    repeat(exp) { p *= base }
    return p
}

private val PRIMES = listOf(
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97
)

// سهل

private fun seqAdd(r: Random): SeqSpec {
    val start = r.nextInt(1, 21)
    val d = r.nextInt(2, 10)
    val all = List(6) { start + d * it }
    return SeqSpec(all.take(5), all[5], Msg("seq.add", listOf(d.toString())))
}

private fun seqSub(r: Random): SeqSpec {
    val start = r.nextInt(50, 91)
    val d = r.nextInt(2, 10)
    val all = List(6) { start - d * it }
    return SeqSpec(all.take(5), all[5], Msg("seq.sub", listOf(d.toString())))
}

private fun seqDouble(r: Random): SeqSpec {
    val start = r.nextInt(1, 6)
    val all = List(6) { start * pow(2, it) }
    return SeqSpec(all.take(5), all[5], Msg("seq.mul", listOf("2")))
}

// متوسط

private fun seqSquares(r: Random): SeqSpec {
    val n0 = r.nextInt(1, 5)
    val all = List(6) { (n0 + it) * (n0 + it) }
    return SeqSpec(all.take(5), all[5], Msg("seq.squares"))
}

private fun seqTriple(r: Random): SeqSpec {
    val start = r.nextInt(1, 4)
    val all = List(6) { start * pow(3, it) }
    return SeqSpec(all.take(5), all[5], Msg("seq.mul", listOf("3")))
}

private fun seqGrowing(r: Random): SeqSpec {
    val start = r.nextInt(1, 11)
    val d = r.nextInt(1, 4)
    val all = mutableListOf(start)
    for (i in 0 until 5) all.add(all.last() + d + i)
    return SeqSpec(
        all.take(5), all[5],
        Msg("seq.growing", listOf(d.toString(), (d + 1).toString(), (d + 2).toString()))
    )
}

private fun seqAlternate(r: Random): SeqSpec {
    val start = r.nextInt(10, 31)
    val a = r.nextInt(3, 10)
    val b = r.nextInt(1, a)
    val all = mutableListOf(start)
    for (i in 0 until 6) {
        val delta = if (i % 2 == 0) a else -b
        all.add(all.last() + delta)
    }
    return SeqSpec(all.take(6), all[6], Msg("seq.alt", listOf(a.toString(), b.toString())))
}

private fun seqFib(r: Random): SeqSpec {
    val a = r.nextInt(1, 6)
    val b = r.nextInt(1, 6)
    val all = mutableListOf(a, b)
    while (all.size < 7) all.add(all[all.size - 1] + all[all.size - 2])
    return SeqSpec(all.take(6), all[6], Msg("seq.fib"))
}

// صعب

private fun seqMulAdd(r: Random): SeqSpec {
    val m = r.nextInt(2, 4)
    val c = listOf(-1, 1, 2)[r.nextInt(3)]
    val start = r.nextInt(2, 5)
    val all = mutableListOf(start)
    repeat(5) { all.add(all.last() * m + c) }
    val msg = if (c > 0) {
        Msg("seq.muladd", listOf(m.toString(), c.toString()))
    } else {
        Msg("seq.mulsub", listOf(m.toString(), (-c).toString()))
    }
    return SeqSpec(all.take(5), all[5], msg)
}

private fun seqInterleave(r: Random): SeqSpec {
    val a = r.nextInt(1, 10)
    val up = r.nextInt(2, 6)
    val b = r.nextInt(30, 51)
    val down = r.nextInt(2, 6)
    val all = List(8) { k -> if (k % 2 == 0) a + up * (k / 2) else b - down * (k / 2) }
    return SeqSpec(all.take(7), all[7], Msg("seq.inter", listOf(up.toString(), down.toString())))
}

private fun seqPrimes(r: Random): SeqSpec {
    val i0 = r.nextInt(0, 13)
    return SeqSpec(PRIMES.subList(i0, i0 + 5), PRIMES[i0 + 5], Msg("seq.primes"))
}

private fun seqCubes(r: Random): SeqSpec {
    val n0 = r.nextInt(1, 4)
    val all = List(6) { pow(n0 + it, 3) }
    return SeqSpec(all.take(5), all[5], Msg("seq.cubes"))
}

private fun seqSquarePlus(r: Random): SeqSpec {
    val k = r.nextInt(1, 4)
    val n0 = r.nextInt(1, 5)
    val all = List(6) { (n0 + it) * (n0 + it) + k }
    return SeqSpec(all.take(5), all[5], Msg("seq.sqplus", listOf(k.toString())))
}

// ─────────────────────── فئات الشكل المختلف ───────────────────────

/** [family] عائلة الفئة: الفئتان من عائلة واحدة أصعب في التمييز. */
internal class Cat(val id: String, val family: String, val emojis: List<String>)

internal val CATEGORIES = listOf(
    Cat("fruits", "food", listOf("🍎", "🍌", "🍇", "🍓", "🍒", "🍊", "🍋", "🍉", "🍑", "🍍")),
    Cat("vegetables", "food", listOf("🥕", "🥒", "🥔", "🌽", "🍆")),
    Cat("sweets", "food", listOf("🍰", "🍩", "🍪", "🍫", "🍬", "🍭", "🍦", "🍧")),
    Cat("fastFood", "food", listOf("🍔", "🍕", "🌭", "🍟", "🌮", "🌯")),
    Cat(
        "landAnimals", "animals",
        listOf("🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯", "🦁", "🐮", "🐷", "🐵")
    ),
    Cat("seaAnimals", "animals", listOf("🐟", "🐠", "🐡", "🐙", "🦀", "🐬", "🐳", "🦈", "🦐")),
    Cat("birds", "animals", listOf("🐦", "🦅", "🦆", "🦉", "🐔", "🐧")),
    Cat("landVehicles", "transport", listOf("🚗", "🚕", "🚌", "🚎", "🚓", "🚑", "🚒", "🚜", "🚲")),
    // الرموز التي تحتاج محدّد العرض (FE0F) مكتوبة بالرمز العددي ليظهر شكلها الملوّن
    Cat("airVehicles", "transport", listOf("🚁", "✈️", "🚀", "🛩️")),
    Cat("waterVehicles", "transport", listOf("🚢", "⛵", "🚤", "🛥️")),
    Cat("balls", "things", listOf("⚽", "🏀", "🏈", "⚾", "🎾", "🏐", "🎱")),
    Cat("instruments", "things", listOf("🎸", "🎹", "🎺", "🎻", "🥁", "🎷")),
    Cat("clothes", "things", listOf("👕", "👖", "👗", "👟", "👒", "🎩"))
)
