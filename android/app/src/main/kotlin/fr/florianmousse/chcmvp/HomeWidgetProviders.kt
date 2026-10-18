package fr.florianmousse.chcmvp

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class NextMatchWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_next_match)

            val opponent = widgetData.getString("next_match_opponent", null)
            val date = widgetData.getString("next_match_date", null)
            val time = widgetData.getString("next_match_time", null)

            views.setTextViewText(R.id.next_match_opponent, opponent ?: "Aucun match prévu")
            views.setTextViewText(R.id.next_match_date, date ?: "")
            views.setTextViewText(R.id.next_match_time, time ?: "")

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

class RankingWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_ranking)

            val position = widgetData.getString("ranking_position", null)
            val suffix = widgetData.getString("ranking_suffix", null)
            val points = widgetData.getString("ranking_points", null)

            views.setTextViewText(R.id.ranking_position, position ?: "-")
            views.setTextViewText(R.id.ranking_suffix, suffix ?: "")
            views.setTextViewText(R.id.ranking_points, points ?: "")

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

class LastResultWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_last_result)

            val score = widgetData.getString("last_result_score", null)
            val opponent = widgetData.getString("last_result_opponent", null)
            val mvp = widgetData.getString("last_result_mvp", null)

            views.setTextViewText(R.id.last_result_score, score ?: "-")
            views.setTextViewText(R.id.last_result_opponent, opponent ?: "")
            views.setTextViewText(R.id.last_result_mvp, mvp ?: "")

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
