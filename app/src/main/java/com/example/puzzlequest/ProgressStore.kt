package com.example.puzzlequest

import android.content.Context
import java.util.Locale

/** يحفظ التقدم والتلميحات واللغة على الجهاز فقط. */
class ProgressStore(context: Context) {

    private val prefs = context.getSharedPreferences("puzzle", Context.MODE_PRIVATE)

    /** آخر مستوى تم حلّه في القسم (0 = لم يبدأ). المستوى n متاح إذا n <= progress + 1. */
    fun progress(tier: Tier): Int = prefs.getInt("progress_${tier.name}", 0)

    /** يعيد true إذا كان هذا أول حلّ لهذا المستوى. */
    fun markSolved(tier: Tier, level: Int): Boolean {
        if (level <= progress(tier)) return false
        prefs.edit().putInt("progress_${tier.name}", level).apply()
        return true
    }

    fun hints(): Int = prefs.getInt("hints", START_HINTS)

    fun addHints(n: Int) {
        prefs.edit().putInt("hints", hints() + n).apply()
    }

    fun useHint() {
        prefs.edit().putInt("hints", maxOf(0, hints() - 1)).apply()
    }

    fun langOrdinal(): Int {
        val saved = prefs.getInt("lang", -1)
        if (saved in Lang.values().indices) return saved
        return if (Locale.getDefault().language == "ar") Lang.AR.ordinal else Lang.EN.ordinal
    }

    fun setLang(lang: Lang) {
        prefs.edit().putInt("lang", lang.ordinal).apply()
    }

    companion object {
        const val START_HINTS = 3
    }
}
