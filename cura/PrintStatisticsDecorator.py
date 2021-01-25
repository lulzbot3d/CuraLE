from UM.Scene.SceneNodeDecorator import SceneNodeDecorator


class PrintStatisticsDecorator(SceneNodeDecorator):
    def __init__(self):
        super().__init__()
        self.print_time = {
            "none": 0,
            "inset_0": 0,
            "inset_x": 0,
            "skin": 0,
            "support": 0,
            "skirt": 0,
            "infill": 0,
            "support_infill": 0,
            "travel": 0,
            "retract": 0,
            "support_interface": 0
        }
        self.material_amounts = None

    def hasPrintStatistics(self):
        return True

    def getPrintTime(self):
        return self.print_time

    def setPrintTime(self, time):
        self.print_time["none"] = time

    def getMaterialAmounts(self):
        return self.material_amounts

    def setMaterialAmounts(self, amounts):
        self.material_amounts = amounts
