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

namespace TomasChochola\Migrations\Oracle;

use NoDiscard;
use Override;
use Psr\Log\LoggerInterface;
use TomasChochola\Connection\Oracle\OracleConnection;
use TomasChochola\Migrations\MigrationsInterface;
use UnexpectedValueException;

use function is_string;

/**
 * @no-named-arguments
 */
readonly class OracleMigrations implements MigrationsInterface
{
    private readonly LoggerInterface $logger;

    private readonly OracleConnection $oracle;

    public function __construct(OracleConnection $oracle, LoggerInterface $logger)
    {
        $this->oracle = $oracle;
        $this->logger = $logger;
    }

    #[Override]
    public function end(): void {}

    #[Override]
    public function execute(string $sql): void
    {
        $statement = $this->oracle->parse($sql);

        $statement->execute();
    }

    #[NoDiscard]
    #[Override]
    public function has(string $selector): bool
    {
        $statement = $this->oracle->parse('SELECT COUNT(*) AS COUNT_NUMBER FROM migrations WHERE selector = :selector');

        $statement->bindByName('selector', $selector);
        $statement->execute();

        $row = $statement->fetchAssoc();

        if ($row === null) {
            throw new UnexpectedValueException('$row');
        }

        $count = $row['COUNT_NUMBER'] ?? null;

        if (!is_string($count)) {
            throw new UnexpectedValueException('$count');
        }

        return $count !== '0';
    }

    #[Override]
    public function mark(string $selector): void
    {
        $sql = <<<'SQL'
            INSERT INTO migrations (selector) VALUES (:selector)
            SQL;

        $this->logger->notice('migrator.sql', ['selector' => $selector, 'sql' => $sql]);

        $statement = $this->oracle->parse($sql);

        $statement->bindByName('selector', $selector);
        $statement->execute();
    }

    #[Override]
    public function start(): void
    {
        $sql = <<<'SQL'
            DECLARE
                count_number NUMBER;
            BEGIN
                SELECT COUNT(*)
                INTO count_number
                FROM user_tables
                WHERE table_name = 'MIGRATIONS';

                IF count_number = 0 THEN
                    EXECUTE IMMEDIATE '
                        CREATE TABLE migrations (
                            selector VARCHAR2(255 CHAR) PRIMARY KEY,
                            created_at TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL
                        )
                    ';
                END IF;
            END;
            SQL;

        $this->logger->notice('migrator.sql', ['selector' => 'migrations', 'sql' => $sql]);

        $statement = $this->oracle->parse($sql);

        $statement->execute();
    }
}
