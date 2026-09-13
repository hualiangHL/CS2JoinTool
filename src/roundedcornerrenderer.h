#ifndef ROUNDEDCORNERRENDERER_H
#define ROUNDEDCORNERRENDERER_H

#include <QObject>
#include <QQuickWindow>
#include <QOpenGLFunctions_3_3_Core>
#include <QColor>

class RoundedCornerRenderer : public QObject
{
    Q_OBJECT
public:
    explicit RoundedCornerRenderer(QQuickWindow *window, QObject *parent = nullptr);
    ~RoundedCornerRenderer();

public slots:
    void setRadius(float radius);

private slots:
    void paint();
    void cleanup();

signals:
    void firstFrameReady();

private:
    void initialize();

    QQuickWindow *m_window = nullptr;
    bool m_initialized = false;
    bool m_firstFrameEmitted = false;
    float m_radius = 20.0f;

    
    unsigned int m_program = 0;
    unsigned int m_vbo = 0;
    unsigned int m_vao = 0;
    int m_radiusLoc = -1;
    int m_widthLoc = -1;
    int m_heightLoc = -1;
    int m_dprLoc = -1;

    
    unsigned int m_borderProgram = 0;
    int m_borderRadiusLoc = -1;
    int m_borderWidthLoc = -1;
    int m_borderColorLoc = -1;
    int m_borderWLoc = -1;
    int m_borderHLoc = -1;

    QOpenGLFunctions_3_3_Core *m_gl = nullptr;
};

#endif 
