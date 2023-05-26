# Copyright (c) 2023 Fargo Additive Manufacturing Equipment 3D, LLC
# Cura LE is released under the terms of the LGPLv3 or higher.

from PyQt5.QtCore import Qt, pyqtSignal
from UM.Qt.ListModel import ListModel
from cura.Machines.Models.BaseMaterialsModel import BaseMaterialsModel

# Modified version of the original MaterialBrandsModel file to flip around
# material type and brand, as requested

class MaterialBrandsModel(ListModel):

    def __init__(self, parent = None):
        super().__init__(parent)

        self.addRoleName(Qt.UserRole + 1, "name")
        self.addRoleName(Qt.UserRole + 2, "type")
        self.addRoleName(Qt.UserRole + 3, "colors")

class MaterialTypesModel(BaseMaterialsModel):

    extruderPositionChanged = pyqtSignal()

    def __init__(self, parent = None):
        super().__init__(parent)

        self.addRoleName(Qt.UserRole + 1, "name")
        self.addRoleName(Qt.UserRole + 2, "brands")

        self._update()

    def _update(self):
        if not self._canUpdate():
            return
        super()._update()

        material_item_list = []
        material_group_dict = {}

        # Part 1: Generate the entire tree of material types -> brands -> specific materials
        for root_material_id, container_node in self._available_materials.items():
            # Do not include the materials from a to-be-removed package
            if bool(container_node.getMetaDataEntry("removed", False)):
                continue

            # Only add results for the current printer
            global_stack = self._machine_manager.activeMachine
            if container_node.getMetaDataEntry("definition", "fdmprinter") != global_stack.definition.id:
                continue

            # Add material types we haven't seen yet to the dict, skipping generics
            material_type = container_node.getMetaDataEntry("material", "")
            if material_type not in material_group_dict:
                material_group_dict[material_type] = {}

            # Add material types we haven't seen yet to the dict
            brand = container_node.getMetaDataEntry("brand", "")
            if brand.lower() == "generic":
                continue
            if brand not in material_group_dict[material_type]:
                material_group_dict[material_type][brand] = []

            # Now handle the individual materials
            item = self._createMaterialItem(root_material_id, container_node)
            if item:
                material_group_dict[material_type][brand].append(item)

        # Part 2: Organize the tree into models
        #
        # Normally, the structure of the menu looks like this:
        #     Material Type -> Brand -> Specific Material
        #
        # To illustrate, a branded material menu may look like this:
        #     PLA ┳ IC3D ┳ Yellow PLA
        #         ┃      ┣ Black PLA
        #         ┃      ┗ ...
        #         ┃
        #         ┗ Polymaker ┳ White PLA
        #                     ┗ ...

        for material_type, brand_dict in material_group_dict.items():

            brand_item_list = []
            material_type_item = {
                "name": material_type,
                "brands": MaterialBrandsModel(self)
            }

            for brand, material_list in brand_dict.items():
                material_brand_item = {
                    "name": brand,
                    "type": material_type,
                    "colors": BaseMaterialsModel(self)
                }
                material_brand_item["colors"].clear()

                # Sort materials by name
                material_list = sorted(material_list, key = lambda x: x["name"].upper())
                material_brand_item["colors"].setItems(material_list)

                brand_item_list.append(material_type_item)

            # Sort brand by name
            brand_item_list = sorted(brand_item_list, key = lambda x: x["name"].upper())
            material_type_item["brands"].setItems(brand_item_list)

            material_item_list.append(material_type_item)

        # Sort brand by name
        material_item_list = sorted(material_item_list, key = lambda x: x["name"].upper())
        self.setItems(material_item_list)
