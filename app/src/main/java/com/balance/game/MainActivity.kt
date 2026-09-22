package com.balance.game

import android.graphics.Color
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Bundle
import android.view.View
import android.widget.ProgressBar
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity(), SensorEventListener {

    private lateinit var gameView: GameView
    private lateinit var progressBar: ProgressBar
    private lateinit var scoreText: TextView
    private lateinit var gameOverText: TextView
    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private var tiltX: Float = 0f
    private var isGameOver: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or View.SYSTEM_UI_FLAG_FULLSCREEN
        gameView = findViewById(R.id.gameView)
        progressBar = findViewById(R.id.progressBar)
        scoreText = findViewById(R.id.scoreText)
        gameOverText = findViewById(R.id.gameOverText)
        sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        gameView.setOnClickListener { if (isGameOver) startGame() }
        startGame()
    }

    private fun startGame() {
        isGameOver = false
        gameOverText.visibility = View.GONE
        gameOverText.setTextColor(Color.parseColor("#FF3366"))
        gameOverText.text = "GAME OVER\nTap to Restart"
        gameView.resetGame()
        updateScore(0)
    }

    fun updateScore(score: Int) {
        scoreText.text = "Score: $score"
        progressBar.progress = score
    }

    fun onBallOutOfBounds() {
        if (!isGameOver) { isGameOver = true; gameOverText.visibility = View.VISIBLE }
    }

    fun onGoalReached(score: Int) {
        if (!isGameOver) {
            isGameOver = true
            gameOverText.text = "YOU WIN!\nScore: $score\nTap to Restart"
            gameOverText.setTextColor(Color.parseColor("#00FF88"))
            gameOverText.visibility = View.VISIBLE
        }
    }

    override fun onResume() {
        super.onResume()
        accelerometer?.let { sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME) }
    }
    
    override fun onPause() { super.onPause(); sensorManager.unregisterListener(this) }
    
    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == Sensor.TYPE_ACCELEROMETER && !isGameOver) {
            tiltX = event.values[0]
            gameView.updateTilt(tiltX)
        }
    }
    
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
