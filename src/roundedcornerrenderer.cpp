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

static const char *eraseShader = R"(
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

static const char *borderShader = R"(
#version 330 core
uniform float radius;
uniform float borderWidth;
uniform vec4 borderColor;
uniform float width;
uniform float height;
out vec4 fragColor;
void main() {
    vec2 px = vec2(gl_FragCoord.x, height - gl_FragCoord.y);
    vec2 halfSize = vec2(width, height) * 0.5;
    vec2 q = abs(px - halfSize) - (halfSize - vec2(radius));
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
    float halfW = borderWidth * 0.5;
    float aa = 1.0;
    float inner = smoothstep(-halfW - aa, -halfW + aa, d);
    float outer = smoothstep(halfW - aa, halfW + aa, d);
    float alpha = inner * (1.0 - outer);
    fragColor = vec4(borderColor.rgb, borderColor.a * alpha);
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

    
    unsigned int fsErase = m_gl->glCreateShader(GL_FRAGMENT_SHADER);
    m_gl->glShaderSource(fsErase, 1, &eraseShader, nullptr);
    m_gl->glCompileShader(fsErase);

    m_program = m_gl->glCreateProgram();
    m_gl->glAttachShader(m_program, vs);
    m_gl->glAttachShader(m_program, fsErase);
    m_gl->glLinkProgram(m_program);

    m_radiusLoc = m_gl->glGetUniformLocation(m_program, "radius");
    m_widthLoc = m_gl->glGetUniformLocation(m_program, "width");
    m_heightLoc = m_gl->glGetUniformLocation(m_program, "height");
    m_dprLoc = m_gl->glGetUniformLocation(m_program, "dpr");

    
    unsigned int fsBorder = m_gl->glCreateShader(GL_FRAGMENT_SHADER);
    m_gl->glShaderSource(fsBorder, 1, &borderShader, nullptr);
    m_gl->glCompileShader(fsBorder);

    
    int borderCompileStatus = 0;
    m_gl->glGetShaderiv(fsBorder, GL_COMPILE_STATUS, &borderCompileStatus);
    if (!borderCompileStatus) {
        char log[1024];
        m_gl->glGetShaderInfoLog(fsBorder, sizeof(log), nullptr, log);
        qWarning() << "[RoundedCorner] Border shader compile failed:" << log;
    }

    m_borderProgram = m_gl->glCreateProgram();
    m_gl->glAttachShader(m_borderProgram, vs);
    m_gl->glAttachShader(m_borderProgram, fsBorder);
    m_gl->glLinkProgram(m_borderProgram);

    int borderLinkStatus = 0;
    m_gl->glGetProgramiv(m_borderProgram, GL_LINK_STATUS, &borderLinkStatus);
    if (!borderLinkStatus) {
        char log[1024];
        m_gl->glGetProgramInfoLog(m_borderProgram, sizeof(log), nullptr, log);
        qWarning() << "[RoundedCorner] Border program link failed:" << log;
    }

    m_borderRadiusLoc = m_gl->glGetUniformLocation(m_borderProgram, "radius");
    m_borderWidthLoc = m_gl->glGetUniformLocation(m_borderProgram, "borderWidth");
    m_borderColorLoc = m_gl->glGetUniformLocation(m_borderProgram, "borderColor");
    m_borderWLoc = m_gl->glGetUniformLocation(m_borderProgram, "width");
    m_borderHLoc = m_gl->glGetUniformLocation(m_borderProgram, "height");
    qDebug() << "[RoundedCorner] Border uniform locs:" << m_borderRadiusLoc << m_borderWidthLoc << m_borderColorLoc << m_borderWLoc << m_borderHLoc;

    m_gl->glDeleteShader(vs);
    m_gl->glDeleteShader(fsErase);
    m_gl->glDeleteShader(fsBorder);

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
    qDebug() << "[RoundedCorner] OpenGL renderer initialized (erase+border), radius=" << m_radius;
}

void RoundedCornerRenderer::paint()
{
    if (!m_initialized) {
        initialize();
        if (!m_initialized) return;
    }
    if (!m_gl) return;

    m_window->beginExternalCommands();

    
    GLint viewport[4];
    m_gl->glGetIntegerv(GL_VIEWPORT, viewport);
    float fbWidth = (float)viewport[2];
    float fbHeight = (float)viewport[3];
    float actualDpr = (m_window->width() > 0) ? (fbWidth / (float)m_window->width()) : 1.0f;

    
    m_gl->glEnable(GL_BLEND);
    m_gl->glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_ALPHA);

    m_gl->glUseProgram(m_program);
    m_gl->glUniform1f(m_radiusLoc, m_radius * actualDpr);
    m_gl->glUniform1f(m_widthLoc, fbWidth);
    m_gl->glUniform1f(m_heightLoc, fbHeight);
    m_gl->glUniform1f(m_dprLoc, actualDpr);

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
        m_gl->glDeleteProgram(m_borderProgram);
        m_gl->glDeleteBuffers(1, &m_vbo);
        m_gl->glDeleteVertexArrays(1, &m_vao);
        delete m_gl;
        m_gl = nullptr;
    }
    m_initialized = false;
}
