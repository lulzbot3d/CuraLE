from UM.Scene.SceneNodeDecorator import SceneNodeDecorator


class SliceableObjectDecorator(SceneNodeDecorator):
    def __init__(self):
        super().__init__()
        
    def isSliceable(self):
        return True
