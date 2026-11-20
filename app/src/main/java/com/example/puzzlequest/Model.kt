package com.example.puzzlequest

const val LEVELS_PER_TIER = 30

/** عدد المستويات المحلولة في القسم السابق لفتح القسم التالي. */
const val UNLOCK_AT = 20

enum class Lang { AR, EN }

enum class Tier(val labelKey: String) {
    EASY("tier_easy"),
    MEDIUM("tier_medium"),
    HARD("tier_hard")
}

enum class PuzzleType { SEQUENCE, EQUATION, ODD_ONE }

/** رسالة مترجمة: مفتاح + وسائط. الوسيط الذي يبدأ بـ @ يُعدّ مفتاح ترجمة آخر. */
data class Msg(val key: String, val args: List<String> = emptyList())

/**
 * لغز واحد. كل ما فيه أرقام ورموز، فلا يعتمد على لغة؛
 * أما النصوص (السؤال والشرح) فتُترجم عبر [Msg].
 */
data class Puzzle(
    val type: PuzzleType,
    val prompt: Msg,
    /** التسلسل (آخر عنصر "?") أو أسطر المعادلات. فارغة في لغز الشكل المختلف. */
    val lines: List<String>,
    /** سطر السؤال في المعادلات، مثل: 🍎 + 🍌 = ? */
    val query: String?,
    val options: List<String>,
    val answerIndex: Int,
    val explanation: Msg
)
