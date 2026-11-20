package com.example.puzzlequest

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** تتحقق من أن كل لغز في كل مستوى سليم ولجوابه حل واحد صحيح. */
class PuzzleFactoryTest {

    private fun allPuzzles(): List<Triple<Tier, Int, Puzzle>> {
        val list = mutableListOf<Triple<Tier, Int, Puzzle>>()
        for (tier in Tier.values()) {
            for (level in 1..LEVELS_PER_TIER) {
                list.add(Triple(tier, level, PuzzleFactory.make(tier, level)))
            }
        }
        return list
    }

    @Test
    fun optionsAreValidAndDeterministic() {
        for ((tier, level, p) in allPuzzles()) {
            val label = "$tier/$level"
            assertTrue(label, p.options.size in 4..6)
            assertEquals(label, p.options.size, p.options.toSet().size)
            assertTrue(label, p.answerIndex in p.options.indices)
            if (p.type != PuzzleType.ODD_ONE) {
                assertTrue(label, p.options.all { (it.toIntOrNull() ?: 0) > 0 })
            }
            assertEquals(label, p, PuzzleFactory.make(tier, level))
        }
    }

    @Test
    fun sequencesLookRight() {
        for ((tier, level, p) in allPuzzles()) {
            if (p.type != PuzzleType.SEQUENCE) continue
            val label = "$tier/$level"
            assertTrue(label, p.lines.size in 6..8)
            assertEquals(label, "?", p.lines.last())
            assertTrue(label, p.lines.dropLast(1).all { it.toIntOrNull() != null })
        }
    }

    @Test
    fun oddOneOutHasExpectedTileCount() {
        for ((tier, level, p) in allPuzzles()) {
            if (p.type != PuzzleType.ODD_ONE) continue
            val expected = when (tier) {
                Tier.EASY -> 4
                Tier.MEDIUM -> 5
                Tier.HARD -> 6
            }
            assertEquals("$tier/$level", expected, p.options.size)
        }
    }

    /** نحلّ كل معادلات اللغز بالتجريب ونتأكد أن القيمة المطلوبة وحيدة وتساوي الجواب. */
    @Test
    fun equationsHaveExactlyOneAnswer() {
        for ((tier, level, p) in allPuzzles()) {
            if (p.type != PuzzleType.EQUATION) continue
            val label = "$tier/$level"
            val equations = p.lines.map { line ->
                val sides = line.split(" = ")
                sides[0].split(" + ") to sides[1].toInt()
            }
            val query = p.query!!
            val isProduct = query.contains("×")
            val queryVars = query.substringBefore(" = ").split(if (isProduct) " × " else " + ")
            val vars = (equations.flatMap { it.first } + queryVars).distinct()

            val results = mutableSetOf<Int>()
            for (values in assignments(vars.size, 16)) {
                val env = vars.zip(values).toMap()
                val ok = equations.all { (left, total) -> left.sumOf { env.getValue(it) } == total }
                if (!ok) continue
                val value = if (isProduct) {
                    queryVars.fold(1) { acc, v -> acc * env.getValue(v) }
                } else {
                    queryVars.sumOf { env.getValue(it) }
                }
                results.add(value)
            }
            assertEquals("$label: القيمة المطلوبة غير وحيدة $results", 1, results.size)
            assertEquals(label, p.options[p.answerIndex].toInt(), results.first())
        }
    }

    @Test
    fun allMessagesAreTranslated() {
        for ((tier, level, p) in allPuzzles()) {
            for (m in listOf(p.prompt, p.explanation)) {
                assertTrue("$tier/$level missing ${m.key}", Texts.has(m.key))
                for (lang in Lang.values()) {
                    val text = Texts.text(m.key, lang, m.args)
                    assertFalse("placeholder left in ${m.key}: $text", text.contains("{"))
                }
            }
            for (a in p.explanation.args) {
                if (a.startsWith("@")) assertTrue("missing $a", Texts.has(a.substring(1)))
            }
        }
    }

    private fun assignments(count: Int, max: Int): List<List<Int>> {
        var result: List<List<Int>> = listOf(emptyList())
        repeat(count) {
            result = result.flatMap { prefix -> (1..max).map { prefix + it } }
        }
        return result
    }
}
