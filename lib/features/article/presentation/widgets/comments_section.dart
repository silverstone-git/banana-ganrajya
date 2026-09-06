import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../models/comment.dart';
import '../../providers/comments_provider.dart';

class CommentsSection extends ConsumerStatefulWidget {
  const CommentsSection({super.key, required this.articleId});

  final String articleId;

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  ArticleComment? _replyingTo;
  bool _isPosting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  Future<void> _submitComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty) return;

    setState(() {
      _isPosting = true;
    });

    final success = await ref
        .read(commentsProvider(widget.articleId).notifier)
        .addComment(body, parentId: _replyingTo?.id);

    setState(() {
      _isPosting = false;
    });

    if (success) {
      _commentController.clear();
      _focusNode.unfocus();
      setState(() {
        _replyingTo = null;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post comment. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commentsProvider(widget.articleId));
    final authState = ref.watch(authProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
          child: Row(
            children: [
              Text(
                'READER DISCUSSION',
                style: AppTypography.labelMd.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  _countTotalComments(state.comments).toString(),
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Input Box (Gated)
        _buildInputBox(authState),
        
        const SizedBox(height: 16),

        if (state.isLoading && state.comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.errorMessage != null && state.comments.isEmpty)
          _buildErrorWidget(state.errorMessage!)
        else if (state.comments.isEmpty)
          _buildEmptyWidget()
        else
          _buildCommentsList(state.comments),
      ],
    );
  }

  int _countTotalComments(List<ArticleComment> list) {
    int count = list.length;
    for (final c in list) {
      count += _countTotalComments(c.replies);
    }
    return count;
  }

  Widget _buildCommentsList(List<ArticleComment> comments) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        return _CommentCard(
          comment: comments[index],
          onReply: (cmt) {
            setState(() {
              _replyingTo = cmt;
            });
            _focusNode.requestFocus();
          },
        );
      },
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Column(
        children: [
          Icon(Symbols.chat, size: 36, color: AppColors.secondary),
          const SizedBox(height: 12),
          Text(
            'No Comments Yet',
            style: AppTypography.headlineMd.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to share your thoughts on this editorial.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.secondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          children: [
            const Icon(Symbols.error, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(
              'Failed to load discussion thread.',
              style: AppTypography.labelLg,
            ),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBox(AuthState authState) {
    if (!authState.isAuthenticated) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceContainerHigh),
        ),
        child: Column(
          children: [
            Text(
              'Join the Discussion',
              style: AppTypography.headlineMd.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'To maintain editorial standards, only authenticated subscribers can post comments.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.secondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(authProvider.notifier).login(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              child: Text(
                'LOG IN TO COMMENT',
                style: AppTypography.labelLg.copyWith(color: AppColors.onPrimary),
              ),
            ),
          ],
        ),
      );
    }

    final user = authState.user;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_replyingTo != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(Symbols.reply, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to @${_replyingTo!.userName}',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: Icon(Symbols.close, size: 16, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: user?.pictureUrl != null
                      ? AppNetworkImage(url: user!.pictureUrl!.toString())
                      : Container(
                          color: AppColors.primary,
                          child: Icon(Symbols.person, color: AppColors.onPrimary, size: 18),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _commentController,
                      focusNode: _focusNode,
                      maxLines: null,
                      style: AppTypography.bodyMd.copyWith(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _replyingTo != null ? 'Write a reply...' : 'Add to the story...',
                        hintStyle: AppTypography.bodyMd.copyWith(
                          color: AppColors.secondary.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_isPosting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _submitComment,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.all(8),
                  ),
                  icon: const Icon(Symbols.send, size: 18),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.onReply,
    this.indentLevel = 0,
  });

  final ArticleComment comment;
  final ValueChanged<ArticleComment> onReply;
  final int indentLevel;

  @override
  Widget build(BuildContext context) {
    final hasReplies = comment.replies.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indent spacer guides
          if (indentLevel > 0)
            Row(
              children: List.generate(
                indentLevel,
                (index) => Container(
                  width: 16,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: AppColors.surfaceContainerHigh,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: comment.userAvatar != null
                            ? AppNetworkImage(url: comment.userAvatar!)
                            : Container(
                                color: AppColors.surfaceContainerHigh,
                                child: Icon(
                                  Symbols.person,
                                  color: AppColors.secondary,
                                  size: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.userName,
                            style: AppTypography.labelLg.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _formatDateTime(comment.createdAt),
                            style: AppTypography.labelMd.copyWith(
                              fontSize: 10,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Symbols.reply, size: 16, color: AppColors.secondary),
                      onPressed: () => onReply(comment),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 38, top: 4),
                  child: Text(
                    comment.body,
                    style: AppTypography.bodyMd.copyWith(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                
                // Nested Replies (Recursive compilation!)
                if (hasReplies)
                  Column(
                    children: comment.replies.map((reply) {
                      return _CommentCard(
                        comment: reply,
                        onReply: onReply,
                        indentLevel: indentLevel + 1,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}
