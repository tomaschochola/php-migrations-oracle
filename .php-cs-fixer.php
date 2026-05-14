<?php

/**
 * @author Tomáš Chochola <tomaschochola@tomaschochola.cz>
 * @copyright © 2026 Tomáš Chochola <tomaschochola@tomaschochola.cz>
 *
 * @license CC-BY-ND-4.0
 *
 * @see {@link https://creativecommons.org/licenses/by-nd/4.0/} License
 * @see {@link https://github.com/tomaschochola} GitHub Profile
 * @see {@link https://github.com/sponsors/tomaschochola} GitHub Sponsors
 */

declare(strict_types=1);

use TomasChochola\Tooling\PhpCsFixer\ConfigFactory;
use TomasChochola\Tooling\PhpCsFixer\FinderFactory;
use TomasChochola\Tooling\PhpCsFixer\PHP85;

return ConfigFactory::create(FinderFactory::create()->in(__DIR__), \array_replace(PHP85::strictRules(), PHP85::tomasChocholaFileHeaderRules()));
