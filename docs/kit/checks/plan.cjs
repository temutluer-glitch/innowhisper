#!/usr/bin/env node
'use strict';

// Resolve a closing plan, never execute it. Shared by build/deploy and opt-in CI.
// Coverage is confirmed by /init, not inferred from the name of a command.
const fs = require('node:fs');
const path = require('node:path');
const STAGES = ['lint', 'typecheck', 'structure', 'test', 'build'];

function plan(config) {
  const steps = [];
  const errors = [];
  const layers = Array.isArray(config.layers) ? config.layers : [];
  if ((config.layers !== undefined && !Array.isArray(config.layers))
    || layers.some((l) => !l || typeof l !== 'object' || Array.isArray(l))) {
    return { steps: [], errors: ['Record layers as a list of runtime entries with /init checks.'] };
  }
  const names = layers.map((l) => l.name);
  if (names.some((n) => typeof n !== 'string' || !n || n === 'primary') || new Set(names).size !== names.length) {
    return { steps: [], errors: ['Layer names must be non-empty, unique and different from primary; resolve with /init checks.'] };
  }
  const commands = config.commands || {};
  const covered = new Map();
  const validCoverage = (value, label) => {
    if (!Array.isArray(value) || value.some((s) => !STAGES.includes(s)) || new Set(value).size !== value.length) {
      errors.push(`${label}: confirm the stage list with /init checks.`);
      return [];
    }
    return value;
  };
  if (commands.check) {
    if (typeof commands.check !== 'string' || !commands.check.trim()) errors.push('Primary aggregate: record a command string with /init checks.');
    const scope = config.checkLayers;
    const coverage = config.checkCoverage;
    if (!Array.isArray(scope) || scope.some((n) => !names.includes(n)) || new Set(scope).size !== scope.length) {
      errors.push('Primary aggregate: confirm checkLayers with /init checks.');
    }
    if (!coverage || typeof coverage !== 'object' || Array.isArray(coverage)) {
      errors.push('Primary aggregate: confirm checkCoverage with /init checks.');
    } else {
      covered.set('primary', validCoverage(coverage.primary, 'Primary aggregate'));
      const layerCoverage = coverage.layers;
      if (!layerCoverage || typeof layerCoverage !== 'object' || Array.isArray(layerCoverage)
        || Object.keys(layerCoverage).some((n) => !Array.isArray(scope) || !scope.includes(n))) {
        errors.push('Primary aggregate: coverage.layers must match checkLayers.');
      } else if (Array.isArray(scope)) {
        for (const name of scope) covered.set(name, validCoverage(layerCoverage[name], `Aggregate layer ${name}`));
      }
    }
    steps.push({ root: '.', command: commands.check, stages: 'aggregate', runtimes: ['primary', ...(Array.isArray(scope) ? scope : [])] });
  }
  function runtime(name, root, ownCommands, ownCoverage, isLayer) {
    if (typeof root !== 'string' || !root || path.isAbsolute(root) || root.split(/[\\/]/).includes('..')) {
      errors.push(`${name}: root must stay inside the project.`);
      return;
    }
    let stages = covered.get(name) || [];
    // If the primary aggregate covers ANY stage of this layer, append only its
    // missing stages; invoking a layer aggregate again could repeat covered tests.
    if (isLayer && !covered.has(name) && ownCommands.check) {
      if (typeof ownCommands.check !== 'string' || !ownCommands.check.trim()) errors.push(`Layer ${name}: record a check command string.`);
      stages = validCoverage(ownCoverage, `Layer ${name}`);
      steps.push({ root, command: ownCommands.check, stages: 'aggregate', runtimes: [name] });
    }
    for (const stage of STAGES) {
      const command = ownCommands[stage];
      const optional = stage === 'typecheck' || stage === 'structure';
      if (command === false) {
        if (stage === 'test') errors.push(`${name}: tests cannot be explicitly absent.`);
        else if (stages.includes(stage)) errors.push(`${name}: ${stage} is both absent and aggregate-covered.`);
        continue;
      }
      if (optional && command === undefined) continue;
      if (typeof command !== 'string' || !command.trim()) {
        errors.push(`${name}: record commands.${stage} (or explicit absence for non-test stages) with /init checks.`);
      } else if (!stages.includes(stage)) {
        steps.push({ root, command, stages: [stage], runtimes: [name] });
      }
    }
  }
  runtime('primary', '.', commands, null, false);
  for (const layer of layers) runtime(layer.name, layer.root, layer.commands || {}, layer.checkCoverage, true);
  // No executable partial plan on unresolved coverage/commands.
  return { steps: errors.length ? [] : steps, errors };
}

if (require.main === module) {
  try {
    const result = plan(JSON.parse(fs.readFileSync(path.join(process.cwd(), '.ai-eng-kit'), 'utf8')));
    process.stdout.write(JSON.stringify(result, null, 2) + '\n');
    if (result.errors.length) process.exitCode = 1;
  } catch (error) {
    process.stderr.write(`Cannot plan checks: ${error.message}\n`);
    process.exitCode = 1;
  }
}
module.exports = { plan, STAGES };
