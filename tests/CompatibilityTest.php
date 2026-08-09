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

namespace Tests;

use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Small;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\MockObject\MockObject;
use Psr\Log\LoggerInterface;
use ReflectionClass;
use Stringable;
use TomasChochola\Database\Oracle\OracleConnection;
use TomasChochola\Database\Oracle\OracleStatement;
use TomasChochola\Migrations\MigrationsInterface;
use TomasChochola\Migrations\Oracle\OracleMigrations;
use UnexpectedValueException;

use function is_array;
use function is_string;
use function str_contains;

/**
 * @internal
 *
 * @no-named-arguments
 */
#[CoversClass(OracleMigrations::class)]
#[Small()]
final class CompatibilityTest extends TestCase
{
    #[Test()]
    public function currentContractRemainsImplemented(): void
    {
        self::assertTrue((new ReflectionClass(OracleMigrations::class))->implementsInterface(MigrationsInterface::class));
    }

    #[Test()]
    public function endingMigrationStorageHasNoAdditionalSideEffects(): void
    {
        $oracle = $this->createOracleConnectionMock();
        $logger = $this->createMock(LoggerInterface::class);

        $oracle->expects($this->never())->method('parse')->seal();
        $logger->expects($this->never())->method('log')->seal();
        (new OracleMigrations($oracle, $logger))->end();
    }

    #[Test()]
    public function executesMigrationSqlThroughOracleStatement(): void
    {
        $statement = $this->createOracleStatementMock();
        $oracle = $this->createOracleConnectionMock();

        $oracle->expects($this->once())->method('parse')->with('SELECT 1')->willReturn($statement)->seal();
        $statement->expects($this->once())->method('execute')->seal();
        (new OracleMigrations($oracle, self::createStub(LoggerInterface::class)))->execute('SELECT 1');
    }

    #[Test()]
    public function malformedMigrationStateIsRejected(): void
    {
        $statement = $this->createOracleStatementMock();
        $oracle = $this->createOracleConnectionMock();

        $oracle->expects($this->once())->method('parse')->willReturn($statement)->seal();
        $statement->expects($this->once())->method('bindByName');
        $statement->expects($this->once())->method('execute');
        $statement->expects($this->once())->method('fetchAssoc')->willReturn(['COUNT_NUMBER' => 1])->seal();

        $this->expectException(UnexpectedValueException::class);

        self::assertFalse((new OracleMigrations($oracle, self::createStub(LoggerInterface::class)))->has('migration'));
    }

    #[Test()]
    public function markingMigrationBindsExecutesAndLogsTheSelector(): void
    {
        $statement = $this->createOracleStatementMock();
        $oracle = $this->createOracleConnectionMock();
        $logger = $this->createMock(LoggerInterface::class);
        $sql = 'INSERT INTO migrations (selector) VALUES (:selector)';

        $logger->expects($this->once())->method('notice')->with('migrator.sql', ['selector' => 'migration', 'sql' => $sql])->seal();
        $oracle->expects($this->once())->method('parse')->with($sql)->willReturn($statement)->seal();
        $statement->expects($this->once())->method('bindByName')->with('selector', 'migration');
        $statement->expects($this->once())->method('execute')->seal();
        (new OracleMigrations($oracle, $logger))->mark('migration');
    }

    #[DataProvider('provideMigrationStateIsReadFromOracleCases')]
    #[Test()]
    public function migrationStateIsReadFromOracle(string $count, bool $expected): void
    {
        $statement = $this->createOracleStatementMock();
        $oracle = $this->createOracleConnectionMock();

        $oracle
            ->expects($this->once())
            ->method('parse')
            ->with('SELECT COUNT(*) AS COUNT_NUMBER FROM migrations WHERE selector = :selector')
            ->willReturn($statement)
            ->seal();

        $statement->expects($this->once())->method('bindByName')->with('selector', 'migration');
        $statement->expects($this->once())->method('execute');
        $statement->expects($this->once())->method('fetchAssoc')->willReturn(['COUNT_NUMBER' => $count])->seal();

        self::assertSame($expected, (new OracleMigrations($oracle, self::createStub(LoggerInterface::class)))->has('migration'));
    }

    /**
     * @return iterable<string, array{string, bool}>
     */
    public static function provideMigrationStateIsReadFromOracleCases(): iterable
    {
        yield 'pending' => ['0', false];
        yield 'applied' => ['1', true];
    }

    #[Test()]
    public function missingMigrationStateIsRejected(): void
    {
        $statement = $this->createOracleStatementMock();
        $oracle = $this->createOracleConnectionMock();

        $oracle->expects($this->once())->method('parse')->willReturn($statement)->seal();
        $statement->expects($this->once())->method('bindByName');
        $statement->expects($this->once())->method('execute');
        $statement->expects($this->once())->method('fetchAssoc')->willReturn(null)->seal();

        $this->expectException(UnexpectedValueException::class);

        self::assertFalse((new OracleMigrations($oracle, self::createStub(LoggerInterface::class)))->has('migration'));
    }

    #[Test()]
    public function startingMigrationStorageCreatesTheMetadataTableWhenMissing(): void
    {
        $statement = $this->createOracleStatementMock();
        $oracle = $this->createOracleConnectionMock();
        $logger = $this->createMock(LoggerInterface::class);

        $isInitializationSql = static fn(Stringable | string $sql): bool => str_contains((string) $sql, 'WHERE table_name = \'MIGRATIONS\'')
            && str_contains((string) $sql, 'CREATE TABLE migrations');

        $isInitializationContext = static fn(mixed $context): bool => is_array($context)
            && ($context['selector'] ?? null) === 'migrations'
            && isset($context['sql'])
            && is_string($context['sql'])
            && str_contains($context['sql'], 'WHERE table_name = \'MIGRATIONS\'')
            && str_contains($context['sql'], 'CREATE TABLE migrations');

        $logger->expects($this->once())->method('notice')->with('migrator.sql', self::callback($isInitializationContext))->seal();
        $oracle->expects($this->once())->method('parse')->with(self::callback($isInitializationSql))->willReturn($statement)->seal();
        $statement->expects($this->once())->method('execute')->seal();
        (new OracleMigrations($oracle, $logger))->start();
    }

    private function createOracleConnectionMock(): MockObject & OracleConnection
    {
        return $this->getMockBuilder(OracleConnection::class)
            ->setConstructorArgs([null])
            ->onlyMethods(['parse'])
            ->getMock();
    }

    private function createOracleStatementMock(): MockObject & OracleStatement
    {
        return $this->getMockBuilder(OracleStatement::class)
            ->setConstructorArgs([null])
            ->onlyMethods(['bindByName', 'execute', 'fetchAssoc'])
            ->getMock();
    }
}
