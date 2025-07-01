from robot.api.deco import keyword, library
from robot.api import logger
from robot.libraries.BuiltIn import BuiltIn
from typing import List, Tuple
from CopadoAI import CopadoAI
import inspect
import re

@library
class ACNCopadoAI:
    """
    Custom library for extending the Copado AI library
    
    """
    
    ROBOT_LIBRARY_VERSION = '1.0.0'
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    THRESHOLD_PATTERN = r'\((\.\d+)\)'
    DEFAULT_THRESHOLD = 0.75

    def __init__(self):
        self.ai = CopadoAI()
        # for name, method in inspect.getmembers(self.ai, predicate=inspect.ismethod):
        #         if not name.startswith('_'):  # Skip private/internal methods
        #             logger.console(name)
        # get_context_faithfulness
        # get_context_precision
        # get_factual_correctness
        # get_hallucination
        # get_noise_sensitivity
        # get_response_helpfulness
        # get_response_relevance
        # get_response_similarity
        # get_text_similarity
        # prompt
        # verify_context_faithfulness
        # verify_context_precision
        # verify_factual_correctness
        # verify_hallucination
        # verify_noise_sensitivity
        # verify_response_helpfulness
        # verify_response_relevance
        # verify_response_similarity
        # verify_text_similarity

    def _eval_score(self, metric_name: str, score: float, threshold: float) -> bool:
        """
        Evaluate the score against the threshold and log the result.
        Returns True if the score meets or exceeds the threshold.
        """
        passed = score >= threshold
        result = "PASS" if passed else "FAIL"
        logger.info(f"{metric_name}: {score:.3f} >= {threshold:.3f} ? {result}")
        return passed

        
    @keyword('Evaluate Metrics')
    def evaluate_metrics(self, eval_metrics: List[str], prompt: str, expected_reply: str, actual_reply: str, context: str):
        all_passed = True
        failure_messages = []

        for short_metric in eval_metrics:
            matches = re.findall(self.__class__.THRESHOLD_PATTERN, short_metric)
            threshold = float(matches[0]) if matches else float(self.__class__.DEFAULT_THRESHOLD)
            metric_code = short_metric[:2].lower()

            match metric_code:
                case 'cf':
                    metric = 'Context Faithfulness'
                    score = self.ai.get_context_faithfulness(prompt, actual_reply, context)
                    passed = self._eval_score(metric, score, threshold)
                case 'cp':
                    metric = 'Context Precision'
                    score = self.ai.get_context_precision(prompt, actual_reply, context)
                    passed = self._eval_score(metric, score, threshold)
                case 'fc':
                    metric = 'Factual Correctness'
                    score = self.ai.get_factual_correctness(actual_reply, context)
                    passed = self._eval_score(metric, score, threshold)
                case 'rr':
                    metric = 'Response Relevance'
                    score = self.ai.get_response_relevance(prompt, actual_reply)
                    passed = self._eval_score(metric, score, threshold)
                case 's':
                    metric = 'Similarity'
                    score = self.ai.get_similarity(expected_reply, actual_reply)
                    passed = self._eval_score(metric, score, threshold)
                case _:
                    error_msg = f"No evaluation metric matching: {metric_code}"
                    failure_messages.append(error_msg)
                    passed = False

            if not passed:
                failure_messages.append(f"{metric} score below threshold ({score} < {threshold})")
                all_passed = False

        if not all_passed:
            BuiltIn().fail("Evaluation failed for one or more metrics:\n" + "\n,".join(failure_messages))



