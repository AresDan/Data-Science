from mrjob.job import MRJob
from mrjob.step import MRStep
import re

WORD_RE = re.compile(r"[\w']+")

class MRWC(MRJob):
    
    def steps(self):
        return [
            MRStep(mapper=self.mapper_get_words,
                   combiner=self.combiner_count_words,
                   reducer=self.reduce_count_words)
            
        ]
    
    def mapper_get_words(self, _, line):
        for word in WORD_RE.findall(line):
            yield (word.lower(), 1)
    
    def combiner_count_words(self, words, count):
        yield (words, sum(count))
    
    def reduce_count_words(self, words, count):
        yield (words, sum(count))


if __name__ == "__main__":
    MRWC.run()