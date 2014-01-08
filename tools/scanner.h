#pragma once

static int const LDI=   (14 << 23) | (0 << 17) | (0 << 16);
static int const XORIH= (14 << 23) | (0 << 17) | (1 << 16);
static int const LD=    (14 << 23) | (1 << 17) | (0 << 11);
static int const ST=    (14 << 23) | (1 << 17) | (1 << 11);
static int const CX= (15 << 23) | 0;
