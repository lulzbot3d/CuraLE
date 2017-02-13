from UM.Extension import Extension
from os import walk
import os
import configparser, json
from UM.Settings.ContainerRegistry import ContainerRegistry

class Import(Extension):
    def __init__(self):
        super().__init__()
        self.addMenuItem("Import", self._import)
        # self.addMenuItem("Rename", self._rename)

    def _import(self):
        path = "/home/victor/cura/cura_orig/resources/quickprint/lulzbot_TAZ_5_SingleV1"

        # profiles = []

        for (dir, dirs, files) in walk(path):
            if dir == path:
                for d1 in dirs:
                    f = "%s/%s/%s" % (dir, d1, "material.ini")
                    parser = configparser.ConfigParser()
                    parser.read(f)
                    try:
                        name = parser.get("info", "name")
                        # print("material:", name)

                        path = "%s/%s" % (dir, d1)
                        for (dir1, dirs1, files1) in walk(path):
                            for dir2 in dirs1:
                                f1 = "%s/%s/profile.ini" % (dir1, dir2)
                                p2 = configparser.ConfigParser()
                                p2.read(f1)
                                try:
                                    n = p2.get("info", "name")
                                    p = p2.get("info", "profile_file")
                                    f2 = os.path.join("%s/%s"%(dir1, dir2), p)
                                    ContainerRegistry.getInstance().importProfile(f2)
                                    # profiles.append({"name": n, "file": f2, "material": name})
                                except:
                                    pass
                        # print("---------------")
                    except:
                        pass

        # print(json.dumps(profiles, indent=4))
        # self._pd = profiles

    # def _rename(self):
    #     path = "/home/victor/.local/share/cura2_lulzbot/quality"
    #
    #     for (dir, dirs, files) in walk(path):
    #         for file in files:
    #             f = "%s/%s" % (dir, file)
    #             name = os.path.split(file)[0]
    #             def find(n):
    #                 for p in self._pd:
    #                     if n in p["file"]:
    #                         return p
    #             profile = find(name)
    #             if not profile:
    #                 continue
    #             cont = open(f, "r").read()
    #             cont = cont.replace("[metadata]", "[metadata]\nquality_type = %s\nmaterial = %s" % (name, profile["material"]))
    #             cont = cont.replace("[general]", "[general]\nname = %s" % profile["name"])
    #             open(f, "w").write(cont)
