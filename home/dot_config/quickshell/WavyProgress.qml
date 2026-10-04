import QtQuick

// Barra de progreso con onda en la parte reproducida
Canvas {
    id: root

    property real progress: 0
    property bool animating: false
    property real phase: 0

    signal seek(real fraction)

    implicitHeight: 16
    onProgressChanged: requestPaint()
    onPhaseChanged: requestPaint()
    onWidthChanged: requestPaint()

    NumberAnimation on phase {
        from: 0
        to: -2 * Math.PI
        duration: 1500
        loops: Animation.Infinite
        running: root.animating
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.lineWidth = 3;
        ctx.lineCap = "round";
        const mid = height / 2;
        const px = Math.max(2, width * Math.min(1, progress));

        ctx.strokeStyle = String(Theme.text);
        ctx.beginPath();
        for (let x = 2; x <= px; x++) {
            const y = mid + Math.sin(x / 4 + phase) * 3;
            if (x === 2) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        }
        ctx.stroke();

        if (px + 6 < width - 2) {
            ctx.strokeStyle = String(Theme.dot);
            ctx.beginPath();
            ctx.moveTo(px + 6, mid);
            ctx.lineTo(width - 2, mid);
            ctx.stroke();
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: e => root.seek(e.x / root.width)
    }
}
