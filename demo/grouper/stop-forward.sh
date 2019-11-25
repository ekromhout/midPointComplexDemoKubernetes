#!/bin/bash
ps -ef |grep forward |grep kubectl|cut -b 9-16|xargs kill -9
