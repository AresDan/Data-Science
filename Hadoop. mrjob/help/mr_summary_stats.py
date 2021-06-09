from mrjob.job import MRJob
from mrjob.step import MRStep

class MRWC(MRJob):
    
    def steps(self):
        return [
            MRStep(mapper=self.mapper_in,
                   reducer=self.reduce_sum_values),
            MRStep(reducer=self.reduce_calc_mean_var)
        ]
    
    def mapper_in(self, _, line):
        label = line.split()[0]
        value = float(line.split()[1])
        
        yield label, [1, value, value**2]
    
    def reduce_sum_values(self, label, values):
    
        sum_of_el = 0
        sum_of_elem = 0
        sum_of_elem_sq = 0
        
        for elem in values:
            sum_of_el += elem[0]
            sum_of_elem += elem[1]
            sum_of_elem_sq += elem[2]
            
        yield label, [sum_of_el, sum_of_elem, sum_of_elem_sq]
    
    def reduce_calc_mean_var(self, label, values):
        # value[0] - num_of_samples
        # value[1] - sum of elem
        # value[2] - sum of elem^2
        
        values_list = list(values)[0]
        
        num_of_samples = values_list[0]
        mean = values_list[1] / num_of_samples
        var = (values_list[2] / num_of_samples) - mean**2
        
        yield label, [num_of_samples, mean, var]


if __name__ == "__main__":
    MRWC.run()