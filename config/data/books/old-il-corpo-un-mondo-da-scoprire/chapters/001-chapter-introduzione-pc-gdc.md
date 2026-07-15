---
access: "draft"
color: "neutro"
description: "Una chiave di lettura per orientarsi nel percorso"
title: "Introduzione"
---

[Contenuto da completare]

rails g model Book slug:string title:string description:text folder_md:string index_file:string price_euro:decimal price_dash:decimal access_mode:integer active:boolean
rails g model BookDomain book:references domain:references
