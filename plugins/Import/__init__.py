from . import Import

def getMetaData():
    return {
        "type": "extension",
        "plugin":
        {
            "name": "Import",
            "author": "",
            "version": "2.2",
            "api": 3,
            "description": ""
        }
    }


def register(app):
    return {"extension": Import.Import()}
