Presentation
------------
MLJS is a Matlab/C++ software intended to jointly segment images using graph cuts and is distributed under LGPL license. This software is illustrated for segmenting hyperspectral data but can be adapted to other applications without difficulty. An example is provided below with Naive Bayes segmentation (left) and two variants of the proposed approach (middle and right):

![Results](https://i.ibb.co/qgVL6tk/foobar.png)

Noticeably, the underlying energy function is globally minimized in binary segmentation, whatever he number of input images. When the number of classes is larger, the minimizer is within some constant from the global one. The current implementation requires that all images are of the same size but could theoretically be different as soon as a mapping between them is made available. We refer to [1] for more details about this point and theoretical aspects. Finally, please note that this software is based on `GCoptimization`, a [Matlab/C++ wrapper](https://github.com/nsubtil/gco-v3.0) for performing graph cuts energy minimization.

If you use this software for research purposes, you should cite the paper below in any resulting publication.

> [1] [N. Lermé, S. Le Hégarat-Mascle, F. Malgouyres, M. Lachaize, "Multi-Layer Joint Segmentation Using MRF and Graph Cuts", Journal of Mathematical Vision and Imaging, vol. 62, num. 6, pages 961-981, 2019.](https://hal.archives-ouvertes.fr/hal-02125044v3/document)
