---
# DOC STATUS
# ------------------------------------------------------------------------------
# 100% done
# Looking good!
# ------------------------------------------------------------------------------
title: HTTP
---

# HTTP

Uvicore has a blazing fast HTTP Kernel with a dual routing system.

Uvicore's [API Router](./api/routing) use the amazing and blazing fast **[FastAPI](https://fastapi.tiangolo.com/)** Kernel.

Uvicore's [Web Router](./web/routing) use the amazing and blazing fast **[Starlette](https://www.starlette.io/)** Kernel.

In the end, even FastAPI is actually Starlette under the hood.  So the real "star" of the HTTP show here in Uvicore is **Tom Christie's Starlette and we LOVE it!**  Blazing Fast uWSGI!

Uvicore makes working with both Web and API routes seamless and integrates extra functionality like RBAC permission control, automatic model routing and Inversion of Control power!
