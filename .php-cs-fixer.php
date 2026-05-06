<?php

declare(strict_types=1);

use TomasChochola\Tooling\PhpCsFixer\ConfigFactory;
use TomasChochola\Tooling\PhpCsFixer\FinderFactory;
use TomasChochola\Tooling\PhpCsFixer\PHP85;

return ConfigFactory::create(
    FinderFactory::create()->in(__DIR__),
    PHP85::strictRules(),
);
