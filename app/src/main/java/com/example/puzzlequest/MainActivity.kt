@file:OptIn(ExperimentalMaterial3Api::class)

package com.example.puzzlequest

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

private val Bg = Color(0xFF0A0A2A)
private val Panel = Color(0xFF1B1B4B)
private val PanelLight = Color(0xFF2A2A66)
private val Gold = Color(0xFFFFD166)
private val Good = Color(0xFF2EC4B6)
private val Bad = Color(0xFFEF476F)

private fun tierColor(tier: Tier): Color = when (tier) {
    Tier.EASY -> Color(0xFF2EC4B6)
    Tier.MEDIUM -> Color(0xFFFFB703)
    Tier.HARD -> Color(0xFFEF476F)
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val store = ProgressStore(this)
        setContent { PuzzleApp(store) }
    }
}

@Composable
fun PuzzleApp(store: ProgressStore) {
    var langOrd by rememberSaveable { mutableIntStateOf(store.langOrdinal()) }
    val lang = Lang.values()[langOrd]
    var screen by rememberSaveable { mutableStateOf("home") }
    var tierOrd by rememberSaveable { mutableIntStateOf(0) }
    var level by rememberSaveable { mutableIntStateOf(1) }
    var hints by remember { mutableIntStateOf(store.hints()) }
    // يتغير عند كل تقدّم ليُعاد حساب الشاشات التي تعرض التقدم
    var tick by remember { mutableIntStateOf(0) }
    val tier = Tier.values()[tierOrd]

    BackHandler(enabled = screen != "home") {
        screen = if (screen == "game") "levels" else "home"
    }

    MaterialTheme(
        colorScheme = darkColorScheme(
            primary = Gold,
            onPrimary = Color(0xFF2B1B00),
            background = Bg,
            surface = Panel,
            onBackground = Color.White,
            onSurface = Color.White
        )
    ) {
        CompositionLocalProvider(
            LocalLayoutDirection provides if (lang == Lang.AR) LayoutDirection.Rtl else LayoutDirection.Ltr
        ) {
            Surface(color = Bg, modifier = Modifier.fillMaxSize()) {
                when (screen) {
                    "home" -> HomeScreen(
                        lang = lang,
                        tick = tick,
                        store = store,
                        onToggleLang = {
                            val next = if (lang == Lang.AR) Lang.EN else Lang.AR
                            store.setLang(next)
                            langOrd = next.ordinal
                        },
                        onOpenTier = { t ->
                            tierOrd = t.ordinal
                            screen = "levels"
                        }
                    )

                    "levels" -> LevelsScreen(
                        tier = tier,
                        lang = lang,
                        progress = remember(tick, tierOrd) { store.progress(tier) },
                        onBack = { screen = "home" },
                        onOpenLevel = { n ->
                            level = n
                            screen = "game"
                        }
                    )

                    else -> GameScreen(
                        tier = tier,
                        level = level,
                        lang = lang,
                        hints = hints,
                        onBack = { screen = "levels" },
                        onSolved = {
                            val first = store.markSolved(tier, level)
                            // مكافأة: تلميح إضافي عند أول حلّ لكل مستوى خامس
                            val bonus = first && level % 5 == 0
                            if (bonus) store.addHints(1)
                            hints = store.hints()
                            tick++
                            bonus
                        },
                        onUseHint = {
                            store.useHint()
                            hints = store.hints()
                        },
                        onHintReward = {
                            store.addHints(1)
                            hints = store.hints()
                        },
                        onNext = {
                            if (level < LEVELS_PER_TIER) {
                                level += 1
                            } else {
                                screen = "levels"
                            }
                        },
                        onLevels = { screen = "levels" }
                    )
                }
            }
        }
    }
}

// ───────────────────────── الشاشة الرئيسية ─────────────────────────

@Composable
private fun HomeScreen(
    lang: Lang,
    tick: Int,
    store: ProgressStore,
    onToggleLang: () -> Unit,
    onOpenTier: (Tier) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
            TextButton(onClick = onToggleLang) {
                Text(Texts.text("lang_switch", lang), color = Gold)
            }
        }
        Text(
            "🧩",
            fontSize = 64.sp,
            modifier = Modifier.fillMaxWidth(),
            textAlign = TextAlign.Center
        )
        Text(
            Texts.text("app_name", lang),
            fontSize = 34.sp,
            fontWeight = FontWeight.Bold,
            color = Gold,
            modifier = Modifier.fillMaxWidth(),
            textAlign = TextAlign.Center
        )
        Text(
            Texts.text("tagline", lang),
            fontSize = 16.sp,
            color = Color(0xFFB8B8E0),
            modifier = Modifier.fillMaxWidth(),
            textAlign = TextAlign.Center
        )
        Spacer(Modifier.height(8.dp))

        Tier.values().forEach { t ->
            val solved = remember(tick) { store.progress(t) }
            val prev = Tier.values().getOrNull(t.ordinal - 1)
            val locked = prev != null && store.progress(prev) < UNLOCK_AT
            TierCard(
                tier = t,
                lang = lang,
                solved = solved,
                lockedText = if (locked && prev != null) {
                    Texts.text("locked_msg", lang, listOf(UNLOCK_AT.toString(), "@" + prev.labelKey))
                } else null,
                onClick = { if (!locked) onOpenTier(t) }
            )
        }
    }
}

@Composable
private fun TierCard(tier: Tier, lang: Lang, solved: Int, lockedText: String?, onClick: () -> Unit) {
    val color = tierColor(tier)
    Card(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .alpha(if (lockedText != null) 0.55f else 1f),
        colors = CardDefaults.cardColors(containerColor = Panel)
    ) {
        Row(
            modifier = Modifier.padding(18.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(52.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(color),
                contentAlignment = Alignment.Center
            ) {
                Text(if (lockedText != null) "🔒" else "⭐", fontSize = 26.sp)
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(
                    Texts.text(tier.labelKey, lang),
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold,
                    color = color
                )
                if (lockedText != null) {
                    Text(lockedText, fontSize = 13.sp, color = Color(0xFFB8B8E0))
                } else {
                    LinearProgressIndicator(
                        progress = { solved.toFloat() / LEVELS_PER_TIER },
                        modifier = Modifier.fillMaxWidth(),
                        color = color,
                        trackColor = PanelLight
                    )
                    Text(
                        Texts.text("solved_of", lang, listOf(solved.toString(), LEVELS_PER_TIER.toString())),
                        fontSize = 13.sp,
                        color = Color(0xFFB8B8E0)
                    )
                }
            }
        }
    }
}

// ───────────────────────── شاشة المستويات ─────────────────────────

@Composable
private fun LevelsScreen(
    tier: Tier,
    lang: Lang,
    progress: Int,
    onBack: () -> Unit,
    onOpenLevel: (Int) -> Unit
) {
    val color = tierColor(tier)
    Column(Modifier.fillMaxSize().padding(16.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            TextButton(onClick = onBack) { Text(Texts.text("back", lang), color = Gold) }
            Spacer(Modifier.weight(1f))
            Text(
                Texts.text(tier.labelKey, lang),
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                color = color
            )
            Spacer(Modifier.weight(1f))
            Spacer(Modifier.size(64.dp))
        }
        Spacer(Modifier.height(12.dp))
        LazyVerticalGrid(
            columns = GridCells.Fixed(5),
            modifier = Modifier.fillMaxSize(),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            items((1..LEVELS_PER_TIER).toList()) { n ->
                val solved = n <= progress
                val current = n == progress + 1
                val open = solved || current
                val bg = when {
                    solved -> color
                    current -> PanelLight
                    else -> Panel
                }
                Box(
                    modifier = Modifier
                        .aspectRatio(1f)
                        .clip(RoundedCornerShape(14.dp))
                        .background(bg)
                        .alpha(if (open) 1f else 0.45f)
                        .clickable(enabled = open) { onOpenLevel(n) },
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = if (open) n.toString() else "🔒",
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                        color = if (solved) Color(0xFF0A0A2A) else Color.White
                    )
                }
            }
        }
    }
}

// ───────────────────────── شاشة اللعب ─────────────────────────

@Composable
private fun GameScreen(
    tier: Tier,
    level: Int,
    lang: Lang,
    hints: Int,
    onBack: () -> Unit,
    onSolved: () -> Boolean,
    onUseHint: () -> Unit,
    onHintReward: () -> Unit,
    onNext: () -> Unit,
    onLevels: () -> Unit
) {
    val puzzle = remember(tier, level) { PuzzleFactory.make(tier, level) }
    // الخيارات المستبعدة (خاطئة أو بتلميح) كقناع بتّات، ليبقى محفوظاً عند تدوير الشاشة
    var mask by rememberSaveable(tier, level) { mutableIntStateOf(0) }
    var solved by rememberSaveable(tier, level) { mutableStateOf(false) }
    var bonus by rememberSaveable(tier, level) { mutableStateOf(false) }
    var wrongTapped by rememberSaveable(tier, level) { mutableStateOf(false) }
    var showAd by remember { mutableStateOf(false) }
    val color = tierColor(tier)

    fun pick(index: Int) {
        if (solved || (mask and (1 shl index)) != 0) return
        if (index == puzzle.answerIndex) {
            solved = true
            bonus = onSolved()
        } else {
            mask = mask or (1 shl index)
            wrongTapped = true
        }
    }

    fun useHint() {
        if (solved) return
        if (hints <= 0) {
            showAd = true
            return
        }
        val candidates = puzzle.options.indices.filter {
            it != puzzle.answerIndex && (mask and (1 shl it)) == 0
        }
        if (candidates.isNotEmpty()) {
            mask = mask or (1 shl candidates.first())
            onUseHint()
        }
    }

    if (showAd) {
        RewardedAdGate(
            lang = lang,
            onReward = {
                showAd = false
                onHintReward()
            },
            onCancel = { showAd = false }
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            TextButton(onClick = onBack) { Text(Texts.text("back", lang), color = Gold) }
            Spacer(Modifier.weight(1f))
            Text(
                Texts.text("level", lang, listOf(level.toString())),
                fontSize = 20.sp,
                fontWeight = FontWeight.Bold,
                color = color
            )
            Spacer(Modifier.weight(1f))
            FilledTonalButton(
                onClick = { useHint() },
                colors = ButtonDefaults.filledTonalButtonColors(containerColor = PanelLight)
            ) {
                Text("💡 $hints", color = Gold, fontWeight = FontWeight.Bold)
            }
        }

        Text(
            Texts.text(puzzle.prompt.key, lang, puzzle.prompt.args),
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.fillMaxWidth(),
            textAlign = TextAlign.Center
        )

        // الأرقام والمعادلات تُقرأ دائماً من اليسار إلى اليمين حتى في الواجهة العربية
        CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
            PuzzleBoard(puzzle, color)

            if (puzzle.type == PuzzleType.ODD_ONE) {
                puzzle.options.indices.toList().chunked(3).forEach { row ->
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        row.forEach { i ->
                            OptionCard(
                                text = puzzle.options[i],
                                fontSize = 40.sp,
                                height = 86.dp,
                                eliminated = (mask and (1 shl i)) != 0,
                                correct = solved && i == puzzle.answerIndex,
                                modifier = Modifier.weight(1f)
                            ) { pick(i) }
                        }
                        repeat(3 - row.size) { Spacer(Modifier.weight(1f)) }
                    }
                }
            } else {
                puzzle.options.indices.toList().chunked(2).forEach { row ->
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        row.forEach { i ->
                            OptionCard(
                                text = puzzle.options[i],
                                fontSize = 26.sp,
                                height = 68.dp,
                                eliminated = (mask and (1 shl i)) != 0,
                                correct = solved && i == puzzle.answerIndex,
                                modifier = Modifier.weight(1f)
                            ) { pick(i) }
                        }
                        repeat(2 - row.size) { Spacer(Modifier.weight(1f)) }
                    }
                }
            }
        }

        if (!solved && wrongTapped) {
            Text(
                Texts.text("try_again", lang),
                color = Bad,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center
            )
        }

        if (solved) {
            ResultPanel(
                puzzle = puzzle,
                lang = lang,
                bonus = bonus,
                isLast = level >= LEVELS_PER_TIER,
                onNext = onNext,
                onLevels = onLevels
            )
        }
    }
}

@Composable
private fun PuzzleBoard(puzzle: Puzzle, color: Color) {
    when (puzzle.type) {
        PuzzleType.SEQUENCE -> {
            Row(Modifier.fillMaxWidth()) {
                puzzle.lines.forEach { item ->
                    val isQuestion = item == "?"
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .padding(horizontal = 2.dp)
                            .aspectRatio(0.8f)
                            .clip(RoundedCornerShape(10.dp))
                            .background(if (isQuestion) Gold else Panel),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            item,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                            maxLines = 1,
                            softWrap = false,
                            color = if (isQuestion) Color(0xFF2B1B00) else Color.White
                        )
                    }
                }
            }
        }

        PuzzleType.EQUATION -> {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = Panel)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    puzzle.lines.forEach { line ->
                        Text(line, fontSize = 28.sp, textAlign = TextAlign.Center)
                    }
                    Text(
                        puzzle.query ?: "",
                        fontSize = 30.sp,
                        fontWeight = FontWeight.Bold,
                        color = color,
                        textAlign = TextAlign.Center
                    )
                }
            }
        }

        PuzzleType.ODD_ONE -> Unit // الأشكال نفسها هي الخيارات
    }
}

@Composable
private fun OptionCard(
    text: String,
    fontSize: androidx.compose.ui.unit.TextUnit,
    height: androidx.compose.ui.unit.Dp,
    eliminated: Boolean,
    correct: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    val container = when {
        correct -> Good
        eliminated -> Bad
        else -> PanelLight
    }
    Card(
        onClick = onClick,
        modifier = modifier
            .height(height)
            .alpha(if (eliminated) 0.3f else 1f),
        colors = CardDefaults.cardColors(containerColor = container)
    ) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text(
                text,
                fontSize = fontSize,
                fontWeight = FontWeight.Bold,
                color = if (correct) Color(0xFF0A0A2A) else Color.White
            )
        }
    }
}

@Composable
private fun ResultPanel(
    puzzle: Puzzle,
    lang: Lang,
    bonus: Boolean,
    isLast: Boolean,
    onNext: () -> Unit,
    onLevels: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = Panel)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(18.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Text("🎉 " + Texts.text("well_done", lang), fontSize = 22.sp, fontWeight = FontWeight.Bold, color = Good)
            Text(Texts.text("explanation", lang), fontSize = 13.sp, color = Color(0xFFB8B8E0))
            Text(
                Texts.text(puzzle.explanation.key, lang, puzzle.explanation.args),
                fontSize = 17.sp,
                lineHeight = 26.sp
            )
            if (bonus) {
                Text("💡 " + Texts.text("bonus_hint", lang), color = Gold, fontWeight = FontWeight.Bold)
            }
            if (isLast) {
                Text(Texts.text("tier_done", lang), color = Gold)
                Button(onClick = onLevels, modifier = Modifier.fillMaxWidth()) {
                    Text(Texts.text("to_levels", lang))
                }
            } else {
                Button(onClick = onNext, modifier = Modifier.fillMaxWidth()) {
                    Text(Texts.text("next_level", lang), fontWeight = FontWeight.Bold)
                }
                TextButton(onClick = onLevels, modifier = Modifier.fillMaxWidth()) {
                    Text(Texts.text("to_levels", lang), color = Gold)
                }
            }
        }
    }
}
