---
title: "Pundit"
---

## Overview

Pundit provides resource-based authorization checks for Rails applications.  It is used in Enroll to enforce resource authorization.

## Pundit Helpers

The base Pundit application policy in Enroll offers a large amount of helpers which have already been implemented and will help in the authorization of additional controllers.

Please consider using these 'building blocks' which before creating any custom logic for authorization.

The currently completed helpers exist in the base `ApplicationPolicy` class, and are documented using YARD [here](../../yard/ApplicationPolicy.html).

## New Policy Guidelines

When implementing new policies, there are several guidelines to follow which will minimize new work and provide simplified conventions, making writing a new policy easier:
1. Inherit from `ApplicationPolicy`.
2. Use the existing helpers in the [`ApplicationPolicy` class](../../yard/ApplicationPolicy.html)
3. You want to establish a 1-1 between your permission check methods in your policy class and the standard CRUD methods: create, read, update, delete.