# Helm Chart Creation Skill

## Overview

This skill provides complete patterns and best practices for creating and managing Helm charts. It covers chart structure, templates, values, dependencies, and deployment workflows for packaging Kubernetes applications.

## Key Features

- Complete chart structure and file organization
- Template syntax with Go templating
- Values management for multi-environment deployments
- Helper functions and reusable templates
- Helm commands reference
- Best practices for production charts

## Quick Reference

### Create New Chart

```bash
helm create my-chart
```

### Chart Structure

```
my-chart/
├── Chart.yaml          # Metadata
├── values.yaml         # Default values
├── templates/          # K8s manifests
│   ├── _helpers.tpl    # Helpers
│   ├── deployment.yaml
│   ├── service.yaml
│   └── NOTES.txt       # Post-install notes
└── charts/             # Dependencies
```

### Basic Commands

```bash
# Install
helm install my-release ./my-chart

# Upgrade
helm upgrade my-release ./my-chart

# With custom values
helm install my-release ./my-chart -f custom-values.yaml

# Dry run
helm install my-release ./my-chart --dry-run --debug

# Uninstall
helm uninstall my-release
```

## Files

- `SKILL.md` - Complete skill documentation
- `Examples/` - Real-world chart examples

## Usage

Reference this skill when:
- Creating new Helm charts
- Templating Kubernetes resources
- Setting up multi-environment deployments
- Managing chart dependencies

## Sources

- [Helm Official Documentation](https://helm.sh/docs/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Chart Template Guide](https://helm.sh/docs/chart_template_guide/)
