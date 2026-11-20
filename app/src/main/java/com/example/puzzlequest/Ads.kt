package com.example.puzzlequest

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import kotlinx.coroutines.delay

/**
 * نقطة ربط الإعلانات.
 *
 * الخطوة الحالية: إعلان **تجريبي** محاكى (عدّاد 3 ثوانٍ ثم مكافأة) لتجربة التدفق كاملاً
 * بلا أي حساب إعلانات. في خطوة لاحقة نستبدل هذه الدالة بإعلان مكافأة حقيقي من AdMob
 * دون أن نغيّر بقية اللعبة، لأن اللعبة تستدعي فقط [onReward] و[onCancel].
 */
@Composable
fun RewardedAdGate(lang: Lang, onReward: () -> Unit, onCancel: () -> Unit) {
    var left by remember { mutableIntStateOf(3) }
    LaunchedEffect(Unit) {
        while (left > 0) {
            delay(1000)
            left -= 1
        }
        onReward()
    }
    AlertDialog(
        onDismissRequest = onCancel,
        title = { Text(Texts.text("test_ad", lang)) },
        text = { Text(Texts.text("reward_in", lang, listOf(left.toString()))) },
        confirmButton = {},
        dismissButton = { TextButton(onClick = onCancel) { Text(Texts.text("cancel", lang)) } }
    )
}
