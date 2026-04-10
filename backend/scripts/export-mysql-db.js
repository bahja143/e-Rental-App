const fs = require('fs/promises');
const path = require('path');
const mysql = require('mysql2/promise');
require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

function quoteIdentifier(value) {
  return `\`${String(value).replace(/`/g, '``')}\``;
}

function quoteValue(value) {
  if (value === null || value === undefined) return 'NULL';
  if (Buffer.isBuffer(value)) return `X'${value.toString('hex')}'`;
  if (value instanceof Date) {
    const iso = value.toISOString().slice(0, 19).replace('T', ' ');
    return `'${iso}'`;
  }
  if (typeof value === 'number' && Number.isFinite(value)) return String(value);
  if (typeof value === 'boolean') return value ? '1' : '0';
  if (typeof value === 'object') {
    return quoteValue(JSON.stringify(value));
  }
  return `'${String(value)
    .replace(/\\/g, '\\\\')
    .replace(/\u0000/g, '\\0')
    .replace(/\n/g, '\\n')
    .replace(/\r/g, '\\r')
    .replace(/\t/g, '\\t')
    .replace(/\x08/g, '\\b')
    .replace(/'/g, "\\'")}'`;
}

async function main() {
  const outPath =
    process.argv[2] ||
    path.resolve(__dirname, '..', '..', '.deploy', `local-db-backup-${Date.now()}.sql`);

  const connection = await mysql.createConnection({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    multipleStatements: false,
  });

  try {
    const [tableRows] = await connection.query('SHOW TABLES');
    const tables = tableRows.map((row) => Object.values(row)[0]);

    const lines = [
      'SET FOREIGN_KEY_CHECKS=0;',
      'SET UNIQUE_CHECKS=0;',
      'SET sql_notes=0;',
      '',
      `CREATE DATABASE IF NOT EXISTS ${quoteIdentifier(process.env.DB_NAME)} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`,
      `USE ${quoteIdentifier(process.env.DB_NAME)};`,
      '',
    ];

    for (const table of tables) {
      const [[createRow]] = await connection.query(`SHOW CREATE TABLE ${quoteIdentifier(table)}`);
      const createSql = createRow['Create Table'];
      lines.push(`DROP TABLE IF EXISTS ${quoteIdentifier(table)};`);
      lines.push(`${createSql};`);
      lines.push('');
    }

    for (const table of tables) {
      const [rows] = await connection.query(`SELECT * FROM ${quoteIdentifier(table)}`);
      lines.push(`-- ${table}`);
      if (rows.length === 0) {
        lines.push('');
        continue;
      }

      const columns = Object.keys(rows[0]);
      const columnList = columns.map(quoteIdentifier).join(', ');
      for (const row of rows) {
        const values = columns.map((column) => quoteValue(row[column])).join(', ');
        lines.push(`INSERT INTO ${quoteIdentifier(table)} (${columnList}) VALUES (${values});`);
      }
      lines.push('');
    }

    lines.push('SET sql_notes=1;');
    lines.push('SET UNIQUE_CHECKS=1;');
    lines.push('SET FOREIGN_KEY_CHECKS=1;');
    lines.push('');

    await fs.mkdir(path.dirname(outPath), { recursive: true });
    await fs.writeFile(outPath, lines.join('\n'), 'utf8');
    console.log(outPath);
  } finally {
    await connection.end();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
