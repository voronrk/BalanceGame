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
