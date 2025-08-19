#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import yaml

import os

from collections import namedtuple

YAML_FILE = "./.github/workflows/docker-images.yml"
DOCKERFILE_PATH = "./Dockerfiles/Dockerfile.%s.in"
DOCKERFILE_TARGET = "./Dockerfiles/Dockerfile.%(target_name)s"


if __name__ != "__main__":
	raise Exception("You shouldn't import this script")

if not os.path.exists(YAML_FILE):
	raise Exception("Unable to find %s" % YAML_FILE)

with open(YAML_FILE, "r") as f:
	content = yaml.load(f, Loader=yaml.FullLoader)

	templates_mapping = {}

	matrix_block = content.get("jobs", {"build" : {}})["build"].get("strategy", {"matrix": []})["matrix"]
	exclude = matrix_block.pop("exclude")
	if not matrix_block:
		raise Exception("No matrix block found")

	matrix = [{}]
	for item, content in matrix_block.items():
		_matrix = []
		for matrix_item in matrix:
			for content_item in content:
				_matrix.append({**matrix_item, **{item: content_item}})

		matrix = _matrix

	# Parse exclusions
	excluded = []
	for job in matrix:
		for excluded_block in exclude:
			matched = [job[x] == y for x, y in excluded_block.items()]
			if not False in matched:
				excluded.append(job)

	print("The following jobs are excluded: %s" % excluded)

	for job in matrix:
		if job in excluded:
			continue

		target_name = ("%s_%s_%s_%s" % (
			job["arch"],
			job["namespace"],
			job["template"],
			job["dist"],
		)).replace("/", "_").replace(":", "_").replace(".", "_").replace("-","_")

		templates_mapping.setdefault(job["template"], []).append(
			{
				"target_name" : target_name,
				"arch" : job["arch"],
				"namespace" : job["namespace"],
				"template" : job["template"],
				"tag" : job["dist"],
			}
		)

	for template, targets in templates_mapping.items():
		# Load template
		with open(DOCKERFILE_PATH % template, "r") as t:
			template_content = t.read()

			for target in targets:
				with open(DOCKERFILE_TARGET % target, "w") as a:
					a.write(template_content % target)
