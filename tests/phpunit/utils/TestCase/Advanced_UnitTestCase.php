<?php
/**
 * Abstract Advanced_UnitTestCase.
 *
 * @package plugin-check
 */

namespace WordPress\Plugin_Check\Test_Utils\TestCase;

use WP_UnitTestCase;

abstract class Advanced_UnitTestCase extends WP_UnitTestCase {

	public function assertFileHasCodeInPosition( $actual, $file, $code, $line, $column ) {
		$all_items = isset( $actual[ $file ][ $line ][ $column ] ) ? $actual[ $file ][ $line ][ $column ] : array();

		$found = ! empty( $all_items ) ? wp_list_filter( $all_items, array( 'code' => $code ) ) : array();

		$this->assertSame( count( $found ), 1, "Code {$code} could not be found in {$file} file in line {$line}, column {$column}." );
	}
}
