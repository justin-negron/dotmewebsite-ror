// ============================================================================
// Prettier Configuration - Enterprise Grade
// ============================================================================
// This configuration ensures consistent code formatting across the project
// Compatible with ESLint and follows modern JavaScript best practices
// ============================================================================

module.exports = {
  // Print width - max line length before wrapping
  printWidth: 100,

  // Tab width - number of spaces per indentation level
  tabWidth: 2,

  // Use spaces instead of tabs
  useTabs: false,

  // Semicolons at the end of statements
  semi: false,

  // Use single quotes instead of double quotes
  singleQuote: true,

  // Quote object properties only when needed
  quoteProps: 'as-needed',

  // Use single quotes in JSX
  jsxSingleQuote: false,

  // Trailing commas - ES5 compatible (objects, arrays, etc.)
  trailingComma: 'es5',

  // Spaces inside object literals
  bracketSpacing: true,

  // Bracket same line for HTML/JSX
  bracketSameLine: false,

  // Arrow function parentheses - always include
  arrowParens: 'always',

  // Line endings - LF (Unix style)
  endOfLine: 'lf',

  // Vue-specific settings
  vueIndentScriptAndStyle: false,

  // HTML whitespace sensitivity
  htmlWhitespaceSensitivity: 'css',

  // Embedded language formatting
  embeddedLanguageFormatting: 'auto',

  // Prose wrap - preserve markdown formatting
  proseWrap: 'preserve',

  // Single attribute per line in HTML/JSX
  singleAttributePerLine: false,
}
