# Copyright (c) 2020 Ultimaker B.V.
# Uranium is released under the terms of the LGPLv3 or higher.

from PyQt6.QtCore import Qt, QCoreApplication, QTimer
from PyQt6.QtGui import QPixmap, QColor, QFont, QPen, QPainter
from PyQt6.QtWidgets import QSplashScreen

from UM.Resources import Resources
from UM.Application import Application
from cura import ApplicationMetadata

import time

class CuraSplashScreen(QSplashScreen):
    def __init__(self):
        super().__init__()
        self._scale = 1
        self._version_y_offset = 0  # when extra visual elements are in the background image, move version text down
        splash_image = QPixmap(Resources.getPath(Resources.Images, "cura.jpg"))

        self.setPixmap(splash_image)

        self._current_message = ""

        self._loading_image_rotation_angle = 0

        self._to_stop = False
        self._change_timer = QTimer()
        self._change_timer.setInterval(50)
        self._change_timer.setSingleShot(False)
        self._change_timer.timeout.connect(self.updateLoadingImage)

        self._last_update_time = None

    def show(self):
        super().show()
        self._last_update_time = time.time()
        self._change_timer.start()

    def updateLoadingImage(self):
        if self._to_stop:
            return
        time_since_last_update = min(time.time() - self._last_update_time, 300) # This prevents exceedingly large time values
        self._last_update_time = time.time()
        # Since we don't know how much time actually passed, check how many intervals of 50 we had.
        self._loading_image_rotation_angle -= 10 * (time_since_last_update * 1000 / 50)
        self.repaint()

    # Override the mousePressEvent so the splashscreen doesn't disappear when clicked
    def mousePressEvent(self, mouse_event):
        pass

    def drawContents(self, painter):
        if self._to_stop:
            return

        painter.save()
        painter.setPen(QColor(0, 0, 0, 255))
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing, True)

        version = Application.getInstance().getVersion().split("-")

        # Draw version text
        font = QFont()  # Using system-default font here
        font.setPixelSize(24)
        painter.setFont(font)
        painter.drawText(420, 105 + self._version_y_offset, round(330 * self._scale), round(230 * self._scale), Qt.AlignLeft | Qt.AlignTop, version[0])
        if len(version) > 1:
            font.setPixelSize(26)
            painter.setFont(font)
            painter.setPen(QColor(0, 0, 0, 255))
            painter.drawText(400, 435 + self._version_y_offset, round(330 * self._scale), round(255 * self._scale), Qt.AlignLeft | Qt.AlignTop, version[1])
        painter.setPen(QColor(255, 255, 255, 255))

        # Draw the loading image
        pen = QPen()
        pen.setWidthF(6 * self._scale)
        pen.setColor(QColor(193, 216, 47, 255))
        painter.setPen(pen)
        painter.drawArc(60, 417, round(32 * self._scale), round(32 * self._scale), round(self._loading_image_rotation_angle * 16), 300 * 16)

        # Draw message text
        if self._current_message:
            font = QFont()  # Using system-default font here
            font.setPixelSize(13)
            pen = QPen()
            pen.setColor(QColor(0, 0, 0, 255))
            painter.setPen(pen)
            painter.setFont(font)
            painter.drawText(100, 128, 606, 600,
                             Qt.AlignLeft | Qt.AlignVCenter | Qt.TextWordWrap,
                             self._current_message)

        painter.restore()
        super().drawContents(painter)

    def showMessage(self, message, *args, **kwargs):
        if self._to_stop:
            return

        self._current_message = message
        self.messageChanged.emit(message)
        QCoreApplication.processEvents()  # Used to be .flush() -- this might be the closest alternative, but uncertain.
        self.repaint()

    def close(self):
        # set stop flags
        self._to_stop = True
        self._change_timer.stop()
        super().close()
