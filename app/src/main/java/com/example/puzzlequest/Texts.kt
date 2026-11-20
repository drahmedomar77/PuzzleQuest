package com.example.puzzlequest

/** كل نصوص اللعبة بالعربية والإنجليزية: المفتاح ← (عربي، إنجليزي). */
object Texts {

    private val map: Map<String, Pair<String, String>> = mapOf(
        // عام
        "app_name" to ("تحدّي الألغاز" to "Puzzle Quest"),
        "tagline" to ("هل تستطيع حلّ كل الألغاز؟" to "Can you solve them all?"),
        "tier_easy" to ("سهل" to "Easy"),
        "tier_medium" to ("متوسط" to "Medium"),
        "tier_hard" to ("صعب" to "Hard"),
        "solved_of" to ("{0} من {1} محلولة" to "{0} of {1} solved"),
        "locked_msg" to ("أنهِ {0} مستوى في «{1}» لفتح هذا القسم" to "Solve {0} levels in \"{1}\" to unlock"),
        "level" to ("المستوى {0}" to "Level {0}"),
        "back" to ("رجوع" to "Back"),
        "lang_switch" to ("English" to "العربية"),

        // الأسئلة
        "q_sequence" to ("ما العدد التالي؟" to "What number comes next?"),
        "q_equation" to ("حلّ المعادلات ثم أوجد القيمة المطلوبة" to "Solve the equations, then find the value"),
        "q_odd" to ("اختر الشكل المختلف" to "Pick the odd one out"),

        // نتيجة المستوى
        "well_done" to ("أحسنت!" to "Well done!"),
        "explanation" to ("الشرح" to "Explanation"),
        "next_level" to ("المستوى التالي" to "Next level"),
        "to_levels" to ("المستويات" to "Levels"),
        "bonus_hint" to ("مكافأة: تلميح إضافي" to "Bonus: +1 hint"),

        // التلميحات والإعلان التجريبي
        "no_hints_title" to ("انتهت التلميحات" to "Out of hints"),
        "no_hints_body" to ("شاهد إعلاناً قصيراً لتحصل على تلميح جديد." to "Watch a short ad to get a new hint."),
        "watch_ad" to ("شاهد إعلاناً" to "Watch ad"),
        "cancel" to ("إلغاء" to "Cancel"),
        "test_ad" to ("إعلان تجريبي" to "Test ad"),
        "reward_in" to ("ستحصل على المكافأة بعد {0} ثوانٍ" to "Reward in {0}s"),
        "hint" to ("تلميح" to "Hint"),
        "try_again" to ("ليست هذه الإجابة، جرّب غيرها" to "Not this one, try another"),
        "tier_done" to ("أنهيت كل مستويات هذا القسم! 🎉" to "You finished this tier! 🎉"),

        // شرح التسلسلات
        "seq.add" to ("نضيف {0} في كل مرة" to "Add {0} each time"),
        "seq.sub" to ("نطرح {0} في كل مرة" to "Subtract {0} each time"),
        "seq.mul" to ("نضرب في {0} في كل مرة" to "Multiply by {0} each time"),
        "seq.squares" to ("هذه مربعات الأعداد المتتالية: 1×1، 2×2، 3×3 ..." to "These are consecutive square numbers: 1×1, 2×2, 3×3 ..."),
        "seq.cubes" to ("هذه مكعبات الأعداد المتتالية: 1×1×1، 2×2×2 ..." to "These are consecutive cube numbers: 1×1×1, 2×2×2 ..."),
        "seq.growing" to ("الفرق يزداد واحداً في كل خطوة: +{0}، +{1}، +{2} ..." to "The step grows by 1 each time: +{0}, +{1}, +{2} ..."),
        "seq.alt" to ("نضيف {0} ثم نطرح {1} بالتناوب" to "Alternately add {0} and subtract {1}"),
        "seq.fib" to ("كل عدد هو مجموع العددين اللذين قبله" to "Each number is the sum of the two before it"),
        "seq.muladd" to ("نضرب في {0} ثم نضيف {1}" to "Multiply by {0}, then add {1}"),
        "seq.mulsub" to ("نضرب في {0} ثم نطرح {1}" to "Multiply by {0}, then subtract {1}"),
        "seq.inter" to ("متتاليتان متداخلتان: الأولى تزيد {0} في كل مرة والثانية تنقص {1}" to "Two interleaved sequences: one goes up by {0}, the other goes down by {1}"),
        "seq.primes" to ("هذه الأعداد الأولية بالترتيب" to "These are the prime numbers in order"),
        "seq.sqplus" to ("مربع العدد زائد {0}" to "A square number plus {0}"),

        // شرح المعادلات والشكل المختلف
        "eq.explain" to ("نبدأ بأسهل معادلة ثم نعوّض. الحل: {0}" to "Start with the easiest equation, then substitute. Solution: {0}"),
        "odd.explain" to ("بقية الأشكال من {0}، أما هذا فمن {1}" to "The others belong to {0}; this one belongs to {1}"),

        // أسماء الفئات
        "cat.fruits" to ("الفواكه" to "fruits"),
        "cat.vegetables" to ("الخضروات" to "vegetables"),
        "cat.sweets" to ("الحلويات" to "sweets"),
        "cat.fastFood" to ("الوجبات السريعة" to "fast food"),
        "cat.landAnimals" to ("الحيوانات البرية" to "land animals"),
        "cat.seaAnimals" to ("الحيوانات البحرية" to "sea animals"),
        "cat.birds" to ("الطيور" to "birds"),
        "cat.landVehicles" to ("المركبات البرية" to "land vehicles"),
        "cat.airVehicles" to ("المركبات الجوية" to "air vehicles"),
        "cat.waterVehicles" to ("المركبات المائية" to "water vehicles"),
        "cat.balls" to ("الكرات الرياضية" to "sports balls"),
        "cat.instruments" to ("الآلات الموسيقية" to "musical instruments"),
        "cat.clothes" to ("الملابس" to "clothes")
    )

    fun has(key: String): Boolean = map.containsKey(key)

    fun text(key: String, lang: Lang, args: List<String> = emptyList()): String {
        val pair = map[key] ?: return key
        var result = if (lang == Lang.AR) pair.first else pair.second
        args.forEachIndexed { i, arg ->
            val value = if (arg.startsWith("@")) text(arg.substring(1), lang) else arg
            result = result.replace("{" + i + "}", value)
        }
        return result
    }
}
