#!/bin/sh
#
#  MakeLocalizableStrings.sh
#  Shared
#
#  Created by Michael Reneer on 2/10/16.
#  Copyright © 2016 Michael Reneer. All rights reserved.
#

source_dir="${SOURCE_ROOT}/${PROJECT_NAME}"
genstrings -o ${source_dir}/en.lproj ${source_dir}/*.m
