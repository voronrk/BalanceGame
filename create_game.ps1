# Создаем папки
New-Item -ItemType Directory -Force -Path "app\src\main\java\com\balance\game"
New-Item -ItemType Directory -Force -Path "app\src\main\res\layout"
New-Item -ItemType Directory -Force -Path "app\src\main\res\values"
New-Item -ItemType Directory -Force -Path "app\src\main\res\drawable"

# 1. AndroidManifest.xml
@'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-feature android:name="android.hardware.sensor.accelerometer" android:required="true"/>
    <application
        android:allowBackup="true"
        android:label="@string/app_name"
        android:supportsRtl="true"
        android:theme="@style/Theme.BalanceGame"
        android:screenOrientation="landscape">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="landscape">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
'@ | Out-File -FilePath "app\src\main\AndroidManifest.xml" -Encoding UTF8

# 2. MainActivity.kt
@'
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
'@ | Out-File -FilePath "app\src\main\java\com\balance\game\MainActivity.kt" -Encoding UTF8

# 3. GameView.kt
@'
package com.balance.game

import android.content.Context
import android.graphics.*
import android.util.AttributeSet
import android.view.View
import kotlin.math.abs

class GameView @JvmOverloads constructor(context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0) : View(context, attrs, defStyleAttr) {
    private var ballX: Float = 0f
    private var ballY: Float = 0f
    private var ballRadius: Float = 30f
    private var tiltX: Float = 0f
    private var score: Int = 0
    private var isGameActive: Boolean = false
    private var platformWidth: Float = 0f
    private var platformStartY: Float = 0f
    private var safeZoneWidth: Float = 0f
    private var goalRadius: Float = 40f
    private var goalX: Float = 0f
    private var goalY: Float = 0f

    private val paintBall = Paint().apply { 
        color = Color.WHITE
        isAntiAlias = true
        setShadowLayer(20f, 0f, 0f, Color.parseColor("#00CCFF"))
    }
    
    private val paintPlatform = Paint().apply { 
        color = Color.parseColor("#1A1A2E")
        isAntiAlias = true 
    }
    
    private val paintEdge = Paint().apply { 
        color = Color.parseColor("#FF3366")
        style = Paint.Style.STROKE
        strokeWidth = 8f
        isAntiAlias = true
        setShadowLayer(15f, 0f, 0f, Color.parseColor("#FF3366"))
    }
    
    private val paintSafeZone = Paint().apply { 
        color = Color.parseColor("#00FF88")
        alpha = 100
        isAntiAlias = true 
    }
    
    private val paintGoal = Paint().apply { 
        color = Color.parseColor("#00CCFF")
        style = Paint.Style.STROKE
        strokeWidth = 6f
        isAntiAlias = true
        setShadowLayer(20f, 0f, 0f, Color.parseColor("#00CCFF"))
    }
    
    private val paintGrid = Paint().apply { 
        color = Color.parseColor("#1A1A2E")
        strokeWidth = 2f
        isAntiAlias = true 
    }
    
    private val paintGlow = Paint().apply { 
        color = Color.parseColor("#00CCFF")
        isAntiAlias = true 
    }

    init { resetGame() }
    
    fun resetGame() { 
        ballX = width / 2f
        ballY = height - 200f
        tiltX = 0f
        score = 0
        isGameActive = true
        calculateDimensions()
    }
    
    private fun calculateDimensions() { 
        platformWidth = 400f
        platformStartY = height * 0.3f
        safeZoneWidth = platformWidth * 0.4f
        goalX = width / 2f
        goalY = platformStartY - 50f
    }

    fun updateTilt(tilt: Float) {
        if (!isGameActive) return
        tiltX = tilt
        ballX += (tiltX * 3f)
        val platformLeft = (width - platformWidth) / 2f
        val platformRight = (width + platformWidth) / 2f
        if (ballX < platformLeft + ballRadius) ballX = platformLeft + ballRadius
        if (ballX > platformRight - ballRadius) ballX = platformRight - ballRadius
        val center = width / 2f
        val distanceFromCenter = abs(ballX - center)
        val inSafeZone = distanceFromCenter < (safeZoneWidth / 2f - ballRadius)
        
        if (inSafeZone) {
            score += 1
            if (score > 100) score = 100
            if (context is MainActivity) { 
                (context as MainActivity).updateScore(score)
                if (score >= 100) { 
                    (context as MainActivity).onGoalReached(score)
                    isGameActive = false 
                } 
            }
        } else {
            if (distanceFromCenter > platformWidth / 2f - ballRadius - 10f) { 
                if (context is MainActivity) { 
                    (context as MainActivity).onBallOutOfBounds()
                    isGameActive = false 
                } 
            }
        }
        invalidate()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) { 
        super.onSizeChanged(w, h, oldw, oldh)
        calculateDimensions()
        ballX = w / 2f
        ballY = h - 200f
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val centerX = width / 2f
        
        // Grid
        for (x in 0..width step 100) canvas.drawLine(x.toFloat(), 0f, x.toFloat(), height.toFloat(), paintGrid)
        for (y in 0..height step 100) canvas.drawLine(0f, y.toFloat(), width.toFloat(), y.toFloat(), paintGrid)
        
        // Platform
        val pL = centerX - platformWidth / 2f
        val pR = centerX + platformWidth / 2f
        canvas.drawRect(pL, platformStartY, pR, height.toFloat(), paintPlatform)
        canvas.drawLine(pL, platformStartY, pL, height.toFloat(), paintEdge)
        canvas.drawLine(pR, platformStartY, pR, height.toFloat(), paintEdge)
        
        // Safe zone
        val sL = centerX - safeZoneWidth / 2f
        val sR = centerX + safeZoneWidth / 2f
        canvas.drawRect(sL, platformStartY, sR, height.toFloat(), paintSafeZone)
        
        // Goal
        canvas.drawCircle(goalX, goalY, goalRadius * 1.5f, paintGlow.apply { alpha = 50 })
        canvas.drawCircle(goalX, goalY, goalRadius, paintGoal)
        
        // Ball
        canvas.drawCircle(ballX, ballY, ballRadius, paintBall)
    }
}
'@ | Out-File -FilePath "app\src\main\java\com\balance\game\GameView.kt" -Encoding UTF8

# 4. activity_main.xml
@'
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="#0A0A0F">
    <com.balance.game.GameView android:id="@+id/gameView" android:layout_width="match_parent" android:layout_height="match_parent" />
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
        android:layout_gravity="top" android:layout_marginTop="20dp" android:layout_marginHorizontal="100dp"
        android:orientation="vertical" android:gravity="center">
        <ProgressBar android:id="@+id/progressBar" style="?android:attr/progressBarStyleHorizontal"
            android:layout_width="match_parent" android:layout_height="12dp"
            android:max="100" android:progress="0" android:progressDrawable="@drawable/progress_bar" />
        <TextView android:id="@+id/scoreText" android:layout_width="wrap_content" android:layout_height="wrap_content"
            android:layout_marginTop="10dp" android:text="Score: 0" android:textColor="#FFFFFF" android:textSize="24sp" android:textStyle="bold" />
    </LinearLayout>
    <TextView android:id="@+id/gameOverText" android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:layout_gravity="center" android:text="GAME OVER\nTap to Restart"
        android:textColor="#FF3366" android:textSize="48sp" android:textStyle="bold"
        android:gravity="center" android:visibility="gone" />
</FrameLayout>
'@ | Out-File -FilePath "app\src\main\res\layout\activity_main.xml" -Encoding UTF8

# 5. colors.xml
@'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="black">#FF000000</color>
    <color name="white">#FFFFFFFF</color>
</resources>
'@ | Out-File -FilePath "app\src\main\res\values\colors.xml" -Encoding UTF8

# 6. strings.xml
@'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Balance</string>
</resources>
'@ | Out-File -FilePath "app\src\main\res\values\strings.xml" -Encoding UTF8

# 7. themes.xml
@'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.BalanceGame" parent="Theme.MaterialComponents.DayNight.NoActionBar">
        <item name="android:windowFullscreen">true</item>
        <item name="android:background">#0A0A0F</item>
    </style>
</resources>
'@ | Out-File -FilePath "app\src\main\res\values\themes.xml" -Encoding UTF8

# 8. progress_bar.xml
@'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:id="@android:id/background">
        <shape><corners android:radius="6dp"/><solid android:color="#3300CCFF"/><stroke android:width="2dp" android:color="#00CCFF"/></shape>
    </item>
    <item android:id="@android:id/progress">
        <clip><shape><corners android:radius="6dp"/><solid android:color="#00CCFF"/></shape></clip>
    </item>
</layer-list>
'@ | Out-File -FilePath "app\src\main\res\drawable\progress_bar.xml" -Encoding UTF8

Write-Host "Done! All files created in app/src/main/" -ForegroundColor Green