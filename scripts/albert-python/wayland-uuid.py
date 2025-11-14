# -*- coding: utf-8 -*-

import uuid

from albert import *

md_iid = '4.0'
md_version = "0.2"
md_name = "UUID Generator"
md_description = "Find and copy emojis by name but don't paste them"
md_license = "MIT"
md_url = "https://github.com/literalplus/dotfiles/tree/main/scripts/albert-python/wayland-uuid.py"
md_authors = "@literalplus"


class Plugin(PluginInstance, TriggerQueryHandler):

    def __init__(self):
        PluginInstance.__init__(self)
        TriggerQueryHandler.__init__(self)

    def defaultTrigger(self):
        return 'uuid()'

    def handleTriggerQuery(self, query):
        uid = str(uuid.uuid4())
        formats = [uid, f'"{uid}"', f'UUID.fromString("{uid}")']
        items = []
        print(f"kafka {formats}")

        for fmt in formats:
            items.append(
                StandardItem(
                    id=fmt,
                    icon_factory=lambda emo=fmt: makeGraphemeIcon("🪪"),
                    text=fmt,
                    actions=[
                        Action("copy", "Copy", lambda x=fmt: setClipboardText(x)),
                    ],
                )
            )
        
        query.add(items)
