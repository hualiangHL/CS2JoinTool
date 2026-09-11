#include "roundedcornerrenderer.h"
#include <QOpenGLContext>
#include <QDebug>

static const char *vertexShader = R"(
#version 330 core
layout(location=0) in vec2 aPos;
void main() {
    gl_Position = vec4(aPos, 0.0, 1.0);
}
)";

static const char *fragmentShader = R"(
#version 330 core
uniform float radius;
uniform float width;
uniform float height;
uniform float dpr;
out vec4 fragColor;
void main() {
    vec2 px = vec2(gl_FragCoord.x, height - gl_FragCoord.y);
    vec2 halfSize = vec2(width, height) * 0.5;
    vec2 q = abs(px - halfSize) - (halfSize - vec2(radius));
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
    float aa = 1.5 * dpr;
    float alpha = smoothstep(radius - aa, radius, d);
    fragColor = vec4(0.0, 0.0, 0.0, alpha);
}
)";

RoundedCornerRenderer::RoundedCornerRenderer(QQuickWindow *window, QObject *parent)
    : QObject(parent), m_window(window)
{
    connect(window, &QQuickWindow::afterRendering, this, &RoundedCornerRenderer::paint, Qt::DirectConnection);
    connect(window, &QQuickWindow::sceneGraphInvalidated, this, &RoundedCornerRenderer::cleanup, Qt::DirectConnection);
}

RoundedCornerRenderer::~RoundedCornerRenderer()
{
    cleanup();
}

void RoundedCornerRenderer::setRadius(float radius)
{
    m_radius = radius;
}

void RoundedCornerRenderer::initialize()
{
    if (!QOpenGLContext::currentContext()) {
        qWarning() << "[RoundedCorner] No OpenGL context";
        return;
    }
    m_gl = new QOpenGLFunctions_3_3_Core();
    if (!m_gl->initializeOpenGLFunctions()) {
        qWarning() << "[RoundedCorner] Failed to initialize OpenGL functions";
        delete m_gl;
        m_gl = nullptr;
        return;
    }

    unsigned int vs = m_gl->glCreateShader(GL_VERTEX_SHADER);
    m_gl->glShaderSource(vs, 1, &vertexShader, nullptr);
    m_gl->glCompileShader(vs);

    unsigned int fs = m_gl->glCreateShader(GL_FRAGMENT_SHADER);
    m_gl->glShaderSource(fs, 1, &fragmentShader, nullptr);
    m_gl->glCompileShader(fs);

    m_program = m_gl->glCreateProgram();
    m_gl->glAttachShader(m_program, vs);
    m_gl->glAttachShader(m_program, fs);
    m_gl->glLinkProgram(m_program);

    m_gl->glDeleteShader(vs);
    m_gl->glDeleteShader(fs);

    m_radiusLoc = m_gl->glGetUniformLocation(m_program, "radius");
    m_widthLoc = m_gl->glGetUniformLocation(m_program, "width");
    m_heightLoc = m_gl->glGetUniformLocation(m_program, "height");
    m_dprLoc = m_gl->glGetUniformLocation(m_program, "dpr");

    float vertices[] = {
        -1.0f, -1.0f,
         1.0f, -1.0f,
         1.0f,  1.0f,
        -1.0f,  1.0f,
    };

    m_gl->glGenVertexArrays(1, &m_vao);
    m_gl->glGenBuffers(1, &m_vbo);
    m_gl->glBindVertexArray(m_vao);
    m_gl->glBindBuffer(GL_ARRAY_BUFFER, m_vbo);
    m_gl->glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    m_gl->glEnableVertexAttribArray(0);
    m_gl->glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), nullptr);
    m_gl->glBindVertexArray(0);

    m_initialized = true;
    qDebug() << "[RoundedCorner] OpenGL renderer initialized, radius=" << m_radius;
}

void RoundedCornerRenderer::paint()
{
    if (!m_initialized) {
        initialize();
        if (!m_initialized) return;
    }
    if (!m_gl) return;

    m_window->beginExternalCommands();

    m_gl->glEnable(GL_BLEND);
    m_gl->glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_ALPHA);

    m_gl->glUseProgram(m_program);
    float dpr = m_window->devicePixelRatio();
    m_gl->glUniform1f(m_radiusLoc, m_radius * dpr);
    m_gl->glUniform1f(m_widthLoc, (float)m_window->width() * dpr);
    m_gl->glUniform1f(m_heightLoc, (float)m_window->height() * dpr);
    m_gl->glUniform1f(m_dprLoc, dpr);

    m_gl->glBindVertexArray(m_vao);
    m_gl->glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    m_gl->glBindVertexArray(0);

    m_gl->glDisable(GL_BLEND);

    m_window->endExternalCommands();

    if (!m_firstFrameEmitted) {
        m_firstFrameEmitted = true;
        emit firstFrameReady();
    }
}

void RoundedCornerRenderer::cleanup()
{
    if (!m_initialized) return;
    if (m_gl) {
        m_gl->glDeleteProgram(m_program);
        m_gl->glDeleteBuffers(1, &m_vbo);
        m_gl->glDeleteVertexArrays(1, &m_vao);
        delete m_gl;
        m_gl = nullptr;
    }
    m_initialized = false;
}

