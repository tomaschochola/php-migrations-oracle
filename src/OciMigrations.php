<?php

declare(strict_types=1);

namespace TomasChochola\Migrations\Oci;

use NoDiscard;
use Override;
use Psr\Log\LoggerInterface;
use TomasChochola\Connection\Oci\OciConnection;
use TomasChochola\Migrations\MigrationsInterface;
use UnexpectedValueException;

use function is_string;

readonly class OciMigrations implements MigrationsInterface
{
    private readonly LoggerInterface $logger;
    private readonly OciConnection $oracle;

    public function __construct(OciConnection $oracle, LoggerInterface $logger)
    {
        $this->oracle = $oracle;
        $this->logger = $logger;
    }

    #[NoDiscard]
    #[Override]
    public function has(string $selector): bool
    {
        $row = $this->oracle->statement('SELECT COUNT(*) AS COUNT_NUMBER FROM migrations WHERE selector = :selector')->bindParams(['selector' => $selector])->execute()->fetchAssoc();

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
    public function end(): void
    {
    }

    #[Override]
    public function execute(string $sql): void
    {
        $this->oracle->statement($sql)->execute();
    }

    #[Override]
    public function mark(string $selector): void
    {
        $sql = 'INSERT INTO migrations (selector) VALUES (:selector)';

        $this->logger->notice('migrator.sql', ['selector' => $selector, 'sql' => $sql]);
        $this->oracle->statement($sql)->bindParams(['selector' => $selector])->execute();
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
        $this->oracle->statement($sql)->execute();
    }
}
