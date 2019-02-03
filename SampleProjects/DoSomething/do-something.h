#pragma once
#include <Arduino.h>
int doSomething(void);

struct something {
	int id;
	const char *text;
};

const struct something *findSomething(int id);

