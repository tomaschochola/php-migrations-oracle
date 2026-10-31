import { ESLintConfigBuilder, filePatterns } from '@tomaschochola/tooling-eslint';

export default new ESLintConfigBuilder()
    .addNodeGlobals({ files: filePatterns.scripts })
    .addGitIgnoreFile(import.meta.url)
    .addJavaScriptRecommendedRules({ files: filePatterns.scripts })
    // .addSonarJsRecommendedRules({ files: filePatterns.scripts })
    .toConfig();
