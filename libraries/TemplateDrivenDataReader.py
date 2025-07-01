from DataDriver.AbstractReaderClass import AbstractReaderClass
from DataDriver.ReaderConfig import ReaderConfig, TestCaseData
import csv
from pathlib import Path
from typing import Any, Dict, List
import yaml
from jinja2 import Template, Environment
import time
import os
from robot.api import logger
from robot.libraries.BuiltIn import BuiltIn
from jinja2.exceptions import TemplateError

try:
    from math import nan  # type: ignore
    import openpyxl  # type: ignore  # noqa: F401
    import pandas as pd  # type: ignore
except ImportError as err:
    raise ImportError(
        """Requirements (pandas, openpyxl) for XLSX support are not installed.
Use 'pip install -U robotframework-datadriver[XLS]' to install XLSX support."""
    ) from err

from robot.utils import is_truthy  # type: ignore


class TemplateDrivenDataReader(AbstractReaderClass):
    """
    TemplateDrivenDataReader is an advanced test case reader that supports CSV/Excel files
    with parameter substitution. It integrates a template file containing test cases with a
    YAML data file that provides substitution parameters.

    Features:
    - CSV and Excel file support for test case templates
    - Parameter substitution using Jinja2
    - Detailed logging and error handling using Robot Framework logger
    - Excel sheet selection
    - Data validation and file information retrieval
    """
    ROBOT_LIBRARY_SCOPE = 'TEST SUITE'
    SUPPORTED_FORMATS = ('.csv', '.xlsx')
    CLASS_NAME = 'TemplateDrivenDataReader'

    ### Initialize ###
    def __init__(self, reader_config: ReaderConfig):
        """
        Initialize the reader with configuration.

        Args:
            reader_config: The configuration for the reader including file paths and additional parameters.
                - template_file: File containing the test case templates (CSV/XLSX)
                - data_file: YAML file containing parameter data for substitution
                - sheet_name: (Optional) Excel sheet name to process
        """
        super().__init__(reader_config)
        # 'template_file' holds the file with test case templates (CSV/XLSX)
        self.template_file = reader_config.file
        # 'data_file' holds the YAML file with substitution parameters
        self.data_file = reader_config.kwargs.get('data_file')
        self.sheet_name = reader_config.kwargs.get('sheet_name')
        self.file_type = None
        self.parameters: Dict[str, Any] = {}

        # Log initialization details.
        self._debug("Initializing TemplateDrivenDataReader")
        self._debug(f"Template file: {self.template_file}")
        self._debug(f"Data file: {self.data_file}")
        self._debug(f"Sheet name: {self.sheet_name}")

        try:
            self.parameters = self._load_parameters()
            if self.parameters:
                self._debug(f"Loaded parameters: {self.parameters}")
            else:
                self._warn("No parameters loaded - substitution will be skipped")
        except Exception as e:
            self._error(f"Initialization failed: {str(e)}")
            raise

    ### Utility Functions ###
    def _get_variable_value(self, name: str):
        return BuiltIn().get_variable_value(name)

    def _debug(self, msg: Any, newline: bool = True, stream: str = "stdout"):
        if self._get_variable_value("${LOG LEVEL}") in ["DEBUG", "TRACE"]:
            logger.console(f"[ {self.CLASS_NAME} ] {msg}", newline, stream)

    def _console(self, msg: Any, newline: bool = True, stream: str = "stdout"):
        logger.console(f"[ {self.CLASS_NAME} ] {msg}", newline, stream)

    def _warn(self, msg: Any, html: bool = False):
        logger.warn(f"[ {self.CLASS_NAME} ] {msg}", html)

    def _error(self, msg: Any, html: bool = False):
        logger.error(f"[ {self.CLASS_NAME} ] {msg}", html)


    def _validate_file_type(self, file_path: str) -> str:
        """
        Validate the file type based on its extension.

        Args:
            file_path: Path to the file.

        Returns:
            The validated file extension.

        Raises:
            ValueError: If the file path is empty or has an unsupported extension.
        """
        if not file_path:
            raise ValueError("File path is empty or None")

        _, ext = os.path.splitext(file_path.lower())
        if ext not in self.SUPPORTED_FORMATS:
            raise ValueError(
                f"Unsupported file format: {ext}. Supported: {', '.join(self.SUPPORTED_FORMATS)}"
            )
        self._debug(f"File type '{ext}' validated for file: {file_path}")
        return ext

    def _load_parameters(self) -> Dict[str, Any]:
        """
        Load and validate parameters from a YAML file.

        Returns:
            A dictionary of parameters.

        Raises:
            FileNotFoundError: If the data file (YAML) does not exist.
            ValueError: If the loaded parameters are not in a dictionary format.
        """
        if not self.data_file:
            self._debug("No data file specified; skipping parameter loading.")
            return {}

        try:
            if not os.path.exists(self.data_file):
                raise FileNotFoundError(f"Data file not found: {self.data_file}")

            with open(self.data_file, 'r') as f:
                params = yaml.safe_load(f)
                if not isinstance(params, dict):
                    raise ValueError("Data file must contain a dictionary")
                return params
        except Exception as e:
            self._error(f"Parameter loading error: {str(e)}")
            raise

    def get_time_seconds(self, str):
        """Generate current timestamp in seconds as an integer"""
        return int(time.time())

    def _process_template(self, value: Any) -> Any:
        """
        Recursively process values through the Jinja2 template engine.
        
        Args:
            value: The value to process (can be str, list, dict, or other types)
        
        Returns:
            The processed value maintaining the original structure
        """
        if value is None:
            return None
            
        if isinstance(value, str):
            try:
                # Create Jinja2 environment with custom filter
                env = Environment()
                
                # Register custom filter
                env.filters['time_seconds'] = self.get_time_seconds
                
                # Create template from environment
                template = env.from_string(value)
                processed = template.render(self.parameters)
                self._debug(f"Template processing: '{value}' -> '{processed}'")
                return processed
            except Exception as e:
                self._error(f"Template processing error for '{value}': {str(e)}")
                return value
                
        if isinstance(value, list):
            return [self._process_template(item) for item in value]
            
        if isinstance(value, dict):
            return {k: self._process_template(v) for k, v in value.items()}
            
        return value
        
    def _apply_template_to_testcase_data(self) -> List[TestCaseData]:
        """
        Apply Jinja2 templating to replace tokens in TestCaseData objects.

        Returns:
            A list of TestCaseData objects with replaced values.
        """
        processed_test_cases: List[TestCaseData] = []
        self._debug("Applying parameter substitution to test cases...")

        for index, test_case in enumerate(self.data_table):
            try:
                # Process test case name.
                processed_name = self._process_template(test_case.test_case_name)

                # Process arguments dictionary.
                processed_arguments = {}
                if test_case.arguments:
                    for key, value in test_case.arguments.items():
                        processed_key = self._process_template(key)
                        processed_value = self._process_template(value)
                        processed_arguments[processed_key] = processed_value

                # Process tags list.
                processed_tags = None
                if test_case.tags:
                    processed_tags = [self._process_template(tag) for tag in test_case.tags]

                # Process documentation.
                processed_documentation = self._process_template(test_case.documentation)

                # Create a new TestCaseData object with processed values.
                processed_case = TestCaseData(
                    test_case_name=processed_name,
                    arguments=processed_arguments,
                    tags=processed_tags,
                    documentation=processed_documentation
                )
                processed_test_cases.append(processed_case)
                self._debug(f"Processed test case {index + 1}: {processed_case}")
            except Exception as e:
                self._error(f"Error processing test case: {str(e)}")
                # In case of error, add the original test case without substitution.
                processed_test_cases.append(test_case)

        return processed_test_cases

    def get_data_from_source(self) -> List[TestCaseData]:
        """
        Main method to read and process data from the source template file.

        Returns:
            self.data_table: A list of TestCaseData objects with parameter substitution applied.

        Raises:
            Exception: If any error occurs during data processing.
        """
        try:
            if not self.template_file:
                raise ValueError("No template file specified")

            if not os.path.exists(self.template_file):
                raise FileNotFoundError(f"Template file not found: {self.template_file}")

            self.file_type = self._validate_file_type(self.template_file)
            self._debug(f"Processing {self.file_type} file: {self.template_file}")

            # Read data based on file type.
            if self.file_type == '.csv':
                self._register_csv_dialects()
                self._read_csv_file_to_data_table()
            elif self.file_type == '.xlsx':
                dtype = object if is_truthy(getattr(self, "preserve_xls_types", False)) else str
                data_frame = self._read_data_frame_from_xlsx_file(dtype)
                self._analyse_header(list(data_frame))
                for row_index, row in enumerate(data_frame.values.tolist()):
                    try:
                        self._read_data_from_table(row)
                    except Exception as e:
                        e.row = row_index + 1
                        raise e

            self._debug(f"Data table contents: {self.data_table}")

            # Apply parameter substitution.
            processed_data = self._apply_template_to_testcase_data()
            # Update self.data_table as required by the abstract method contract.
            self.data_table = processed_data
            self._debug(f"Processed data: {self.data_table}")
            return self.data_table

        except Exception as e:
            self._error(f"Data processing error: {str(e)}")
            raise

    def _register_csv_dialects(self):
        """
        Register CSV dialects based on configuration.
        """
        if self.csv_dialect.lower() == "userdefined":
            csv.register_dialect(
                self.csv_dialect,
                delimiter=self.delimiter,
                quotechar=self.quotechar,
                escapechar=self.escapechar,
                doublequote=self.doublequote,
                skipinitialspace=self.skipinitialspace,
                lineterminator=self.lineterminator,
                quoting=csv.QUOTE_ALL,
            )
            self._debug("Registered user-defined CSV dialect.")
        elif self.csv_dialect == "Excel-EU":
            csv.register_dialect(
                self.csv_dialect,
                delimiter=";",
                quotechar='"',
                escapechar="\\",
                doublequote=True,
                skipinitialspace=False,
                lineterminator="\r\n",
                quoting=csv.QUOTE_ALL,
            )
            self._debug("Registered 'Excel-EU' CSV dialect.")

    def _read_csv_file_to_data_table(self):
        """
        Read data from a CSV file and populate the data table.
        """
        with Path(self.template_file).open(encoding=self.csv_encoding) as csvfile:
            reader = csv.reader(csvfile, self.csv_dialect)
            for row_index, row in enumerate(reader):
                try:
                    if row_index == 0:
                        self._analyse_header(row)
                    else:
                        self._read_data_from_table(row)
                except Exception as e:
                    e.row = row_index + 1
                    raise e
            self._debug("CSV file successfully read and processed.")

    def _read_data_frame_from_xlsx_file(self, dtype):
        """
        Read data from an XLSX file using pandas and return a DataFrame.

        Args:
            dtype: The data type to use for the DataFrame columns.

        Returns:
            A pandas DataFrame with the file data.
        """
        self._debug(f"Reading XLSX file: {self.template_file} (sheet: {self.sheet_name})")
        return pd.read_excel(
            self.template_file,
            sheet_name=self.sheet_name,
            dtype=dtype,
            engine="openpyxl",
            na_filter=False
        ).replace(nan, "", regex=True)
