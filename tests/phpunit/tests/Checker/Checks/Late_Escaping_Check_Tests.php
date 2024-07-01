<?php
/**
 * Tests for the Late_Escaping_Check class.
 *
 * @package plugin-check
 */

use WordPress\Plugin_Check\Checker\Check_Context;
use WordPress\Plugin_Check\Checker\Check_Result;
use WordPress\Plugin_Check\Checker\Checks\Late_Escaping_Check;
use WordPress\Plugin_Check\Test_Utils\TestCase\Advanced_UnitTestCase;

class Late_Escaping_Check_Tests extends Advanced_UnitTestCase {

	public function test_run_with_errors() {
		$late_escape_check = new Late_Escaping_Check();
		$check_context     = new Check_Context( UNIT_TESTS_PLUGIN_DIR . 'test-plugin-late-escaping-errors/load.php' );
		$check_result      = new Check_Result( $check_context );

		$late_escape_check->run( $check_result );

		$errors = $check_result->get_errors();

		$this->assertNotEmpty( $errors );
		$this->assertArrayHasKey( 'load.php', $errors );
		$this->assertEquals( 1, $check_result->get_error_count() );

		// Check for WordPress.Security.EscapeOutput error on Line no 24 and column no at 6.
		$this->assertFileHasCodeInPosition( $errors, 'load.php', 'WordPress.Security.EscapeOutput.OutputNotEscaped', 24, 5 );
	}

	public function test_run_without_errors() {
		$late_escape_check = new Late_Escaping_Check();
		$check_context     = new Check_Context( UNIT_TESTS_PLUGIN_DIR . 'test-plugin-late-escaping-without-errors/load.php' );
		$check_result      = new Check_Result( $check_context );

		$late_escape_check->run( $check_result );

		$errors   = $check_result->get_errors();
		$warnings = $check_result->get_warnings();

		$this->assertEmpty( $errors );
		$this->assertEmpty( $warnings );
		$this->assertEquals( 0, $check_result->get_error_count() );
		$this->assertEquals( 0, $check_result->get_warning_count() );
	}
}
