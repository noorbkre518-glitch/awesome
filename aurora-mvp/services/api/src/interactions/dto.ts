import { IsIn, IsOptional, IsUUID } from 'class-validator';

export class LikeDto {
  @IsUUID()
  targetUserId!: string;

  @IsOptional()
  @IsIn(['LIKE', 'SUPER_LIKE'])
  kind?: 'LIKE' | 'SUPER_LIKE';
}
