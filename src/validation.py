#!/usr/bin/env python3
"""
Advanced validation and error handling for Nixernetes CLI
Provides detailed error messages, suggestions, and debugging support
"""

import sys
import os
import json
from typing import Any, Dict, List, Optional, Tuple
from dataclasses import dataclass
from enum import Enum
import traceback


class ErrorLevel(Enum):
    """Error severity levels"""
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


class ErrorCode(Enum):
    """Standard error codes for Nixernetes"""
    CONFIG_NOT_FOUND = "E001"
    INVALID_CONFIG = "E002"
    SYNTAX_ERROR = "E003"
    VALIDATION_FAILED = "E004"
    DEPLOYMENT_FAILED = "E005"
    NETWORK_ERROR = "E006"
    PERMISSION_DENIED = "E007"
    RESOURCE_CONFLICT = "E008"
    TIMEOUT = "E009"
    UNKNOWN_ERROR = "E999"


@dataclass
class ValidationError:
    """Represents a validation error"""
    code: ErrorCode
    level: ErrorLevel
    message: str
    file: Optional[str] = None
    line: Optional[int] = None
    column: Optional[int] = None
    suggestion: Optional[str] = None
    context: Optional[str] = None
    
    def __str__(self) -> str:
        """Format error for display"""
        lines = []
        
        # Header
        prefix = self._get_prefix()
        lines.append(f"{prefix} {self.code.value}: {self.message}")
        
        # Location
        if self.file:
            loc = f"{self.file}"
            if self.line:
                loc += f":{self.line}"
            if self.column:
                loc += f":{self.column}"
            lines.append(f"  at {loc}")
        
        # Context
        if self.context:
            lines.append(f"\n  Context:")
            for ctx_line in self.context.split('\n'):
                lines.append(f"    {ctx_line}")
        
        # Suggestion
        if self.suggestion:
            lines.append(f"\n  Suggestion:")
            for sugg_line in self.suggestion.split('\n'):
                lines.append(f"    {sugg_line}")
        
        return '\n'.join(lines)
    
    def _get_prefix(self) -> str:
        """Get colored prefix based on level"""
        level_map = {
            ErrorLevel.INFO: "ℹ",
            ErrorLevel.WARNING: "⚠",
            ErrorLevel.ERROR: "✗",
            ErrorLevel.CRITICAL: "✗✗",
        }
        return level_map.get(self.level, "•")


class ConfigurationValidator:
    """Validates Nixernetes configurations"""
    
    def __init__(self, strict: bool = False):
        self.strict = strict
        self.errors: List[ValidationError] = []
        self.warnings: List[ValidationError] = []
    
    def validate_file(self, filepath: str) -> bool:
        """Validate a configuration file"""
        try:
            # Check if file exists
            if not os.path.exists(filepath):
                self._add_error(
                    code=ErrorCode.CONFIG_NOT_FOUND,
                    level=ErrorLevel.ERROR,
                    message=f"Configuration file not found: {filepath}",
                    file=filepath,
                    suggestion=f"Check the file path exists:\n  ls -la {filepath}\n\nOr create a new config:\n  nixernetes init my-project"
                )
                return False
            
            # Check file is readable
            if not os.access(filepath, os.R_OK):
                self._add_error(
                    code=ErrorCode.PERMISSION_DENIED,
                    level=ErrorLevel.ERROR,
                    message=f"Permission denied reading: {filepath}",
                    file=filepath,
                    suggestion=f"Fix permissions:\n  chmod 644 {filepath}"
                )
                return False
            
            # Check file extension
            if not filepath.endswith('.nix'):
                self._add_error(
                    code=ErrorCode.INVALID_CONFIG,
                    level=ErrorLevel.WARNING,
                    message=f"File extension is not .nix: {filepath}",
                    file=filepath,
                    suggestion="Configuration files should use .nix extension"
                )
                if self.strict:
                    return False
            
            # Validate nix syntax (basic check)
            with open(filepath, 'r') as f:
                content = f.read()
            
            if not content.strip():
                self._add_error(
                    code=ErrorCode.INVALID_CONFIG,
                    level=ErrorLevel.ERROR,
                    message=f"Configuration file is empty: {filepath}",
                    file=filepath,
                    suggestion="Add configuration to the file"
                )
                return False
            
            # Check for common syntax issues
            self._check_syntax(filepath, content)
            
            return len([e for e in self.errors if e.level == ErrorLevel.ERROR]) == 0
            
        except Exception as e:
            self._add_error(
                code=ErrorCode.UNKNOWN_ERROR,
                level=ErrorLevel.CRITICAL,
                message=f"Unexpected error validating configuration: {str(e)}",
                file=filepath
            )
            return False
    
    def _check_syntax(self, filepath: str, content: str) -> None:
        """Check for common Nix syntax issues"""
        lines = content.split('\n')
        
        for line_no, line in enumerate(lines, 1):
            # Check for common mistakes
            if '=${' in line and '}' not in line:
                self._add_error(
                    code=ErrorCode.SYNTAX_ERROR,
                    level=ErrorLevel.ERROR,
                    message="Unclosed interpolation expression",
                    file=filepath,
                    line=line_no,
                    context=line,
                    suggestion="Ensure all ${ ... } expressions are properly closed"
                )
            
            if line.strip().endswith(';'):
                if not line.strip().startswith('#'):
                    self._add_error(
                        code=ErrorCode.SYNTAX_ERROR,
                        level=ErrorLevel.WARNING,
                        message="Unexpected semicolon at end of line",
                        file=filepath,
                        line=line_no,
                        context=line,
                        suggestion="In Nix, semicolons separate let bindings, not statements"
                    )
    
    def validate_deployment(self, config: Dict[str, Any]) -> bool:
        """Validate deployment configuration"""
        errors = []
        
        # Check required fields
        required_fields = ['name', 'containers']
        for field in required_fields:
            if field not in config:
                errors.append(f"Missing required field: {field}")
        
        # Validate containers
        if 'containers' in config:
            if not isinstance(config['containers'], list):
                errors.append("'containers' must be a list")
            elif len(config['containers']) == 0:
                errors.append("At least one container is required")
            else:
                for i, container in enumerate(config['containers']):
                    if 'image' not in container:
                        errors.append(f"Container {i}: missing 'image' field")
        
        # Add errors
        for error in errors:
            self._add_error(
                code=ErrorCode.VALIDATION_FAILED,
                level=ErrorLevel.ERROR,
                message=error,
                suggestion="Review deployment configuration requirements in MODULE_REFERENCE.md"
            )
        
        return len(errors) == 0
    
    def _add_error(self, **kwargs) -> None:
        """Add an error or warning"""
        error = ValidationError(**kwargs)
        if error.level == ErrorLevel.ERROR or error.level == ErrorLevel.CRITICAL:
            self.errors.append(error)
        else:
            self.warnings.append(error)
    
    def report(self) -> str:
        """Generate validation report"""
        lines = []
        
        if not self.errors and not self.warnings:
            lines.append("✓ Validation passed!")
            return '\n'.join(lines)
        
        if self.warnings:
            lines.append(f"\nWarnings ({len(self.warnings)}):")
            for warning in self.warnings:
                lines.append(str(warning))
        
        if self.errors:
            lines.append(f"\nErrors ({len(self.errors)}):")
            for error in self.errors:
                lines.append(str(error))
        
        lines.append(f"\nSummary: {len(self.errors)} errors, {len(self.warnings)} warnings")
        
        return '\n'.join(lines)


class NixernetesException(Exception):
    """Base exception for Nixernetes errors"""
    
    def __init__(self, code: ErrorCode, message: str, level: ErrorLevel = ErrorLevel.ERROR):
        self.code = code
        self.message = message
        self.level = level
        super().__init__(self.format_error())
    
    def format_error(self) -> str:
        """Format error for display"""
        return f"[{self.code.value}] {self.message}"


class ConfigNotFoundError(NixernetesException):
    """Raised when configuration file is not found"""
    
    def __init__(self, filepath: str):
        super().__init__(
            code=ErrorCode.CONFIG_NOT_FOUND,
            message=f"Configuration file not found: {filepath}"
        )


class ValidationError(NixernetesException):
    """Raised when validation fails"""
    
    def __init__(self, message: str):
        super().__init__(
            code=ErrorCode.VALIDATION_FAILED,
            message=message
        )


class DeploymentError(NixernetesException):
    """Raised when deployment fails"""
    
    def __init__(self, message: str):
        super().__init__(
            code=ErrorCode.DEPLOYMENT_FAILED,
            message=message
        )


def handle_error(error: Exception, verbose: bool = False) -> int:
    """Handle and display error"""
    if isinstance(error, NixernetesException):
        print(f"\n{error.format_error()}", file=sys.stderr)
        if verbose:
            traceback.print_exc()
        return 1
    
    print(f"\n✗ Unexpected error: {str(error)}", file=sys.stderr)
    if verbose:
        traceback.print_exc()
    return 1


def suggest_fixes(error_message: str) -> List[str]:
    """Suggest fixes for common errors"""
    suggestions = []
    
    lower_msg = error_message.lower()
    
    if "not found" in lower_msg:
        suggestions.extend([
            "Check the file path is correct",
            "Use absolute paths for clarity",
            "Verify file permissions: ls -la <file>"
        ])
    
    if "permission denied" in lower_msg:
        suggestions.extend([
            "Check file permissions: ls -la <file>",
            "Fix permissions: chmod 644 <file>",
            "Run with appropriate user/role"
        ])
    
    if "syntax error" in lower_msg:
        suggestions.extend([
            "Review Nix syntax in the configuration",
            "Check for unclosed braces or quotes",
            "Run 'nixernetes validate --detailed' for more info"
        ])
    
    if "connection" in lower_msg or "timeout" in lower_msg:
        suggestions.extend([
            "Check Kubernetes cluster is running",
            "Verify kubectl configuration: kubectl config view",
            "Check network connectivity",
            "Review firewall rules"
        ])
    
    return suggestions


if __name__ == "__main__":
    # Example usage
    validator = ConfigurationValidator(strict=False)
    
    if len(sys.argv) > 1:
        filepath = sys.argv[1]
        is_valid = validator.validate_file(filepath)
        print(validator.report())
        sys.exit(0 if is_valid else 1)
    else:
        print("Configuration validation module for Nixernetes CLI")
        print("Usage: python3 validation.py <config-file>")
