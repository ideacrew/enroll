---
title: "Pundit"
---

## Overview

Pundit provides resource-based authorization checks for Rails applications.  It is used in Enroll to enforce resource authorization.

## Pundit Helpers

The base Pundit application policy in Enroll offers a large amount of helpers which have already been implemented and will help in the authorization of additional controllers.

Please consider using these 'building blocks' which before creating any custom logic for authorization.

The currently completed helpers exist in the base `ApplicationPolicy` class, and are documented using YARD [here](../../yard/ApplicationPolicy.html).