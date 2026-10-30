#!/usr/bin/env node

import { pathToFileURL } from 'node:url'

export function greet(name = '{{PROJECT_TITLE}}'): string {
  return `Hello, ${name}.`
}

function main(): void {
  const arg = process.argv.slice(2).find((a) => !a.startsWith('-'))
  if (process.argv.includes('--help') || process.argv.includes('-h')) {
    console.log('Usage: {{PROJECT_NAME}} [name]')
    return
  }
  console.log(greet(arg))
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  main()
}
