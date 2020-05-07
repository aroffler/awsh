#!/usr/bin/env bash
# Command to show various installed tools 
# and their current running version in a clean list

function tools {
	local TF_VER_11="$(terraform -v | grep 'v0.')"
	local TF_VER_12="$(terraform12 -v | grep 'v0.')"
	local AWS_CLI_VER="$(aws --version | cut -b -15)"
	local AWS_SAM_VER="$(sam --version | cut -b -7,17-)"
	local AMICLEANER_VER="$(amicleaner --version)"
	local AWS_SESSION_MGR_VER="$(session-manager-plugin --version)"

	echo ""
        echo "TOOLS:"
        echo "=========================================="
        echo ""
        echo "      '${TF_VER_11}'     terraform --help"
        echo "      '${TF_VER_12}'    terraform12 --help"
        echo ""
        echo "      '${AWS_CLI_VER}'       aws --help"
        echo ""
        echo "      '${AWS_SAM_VER}'        sam --help"
        echo ""
        echo "      'AMICLEANER ${AMICLEANER_VER}'      amicleaner --help"
        echo ""
        echo "      'AWS Session Manager ${AWS_SESSION_MGR_VER}'    aws ssm start-session --target"
        echo ""
        echo "=========================================="
}

export -f tools