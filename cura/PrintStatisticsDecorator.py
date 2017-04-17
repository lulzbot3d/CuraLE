from UM.Scene.SceneNodeDecorator import SceneNodeDecorator


class PrintStatisticsDecorator(SceneNodeDecorator):
    def __init__(self):
        super().__init__()
        self.print_time = 0

    def hasPrintStatistics(self):
        return True

    def getPrintTime(self):
        return self.print_time

    def setPrintTime(self, time):
        self.print_time = time
